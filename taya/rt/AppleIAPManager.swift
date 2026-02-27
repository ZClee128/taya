import UIKit
import StoreKit

// MARK: - Purchase Types

/// Maximum receipt verification retry attempts before giving up.
private let kMaxVerificationRetries = 9

/// Distinguishes between one-time purchases and auto-renewable subscriptions.
enum ApplePayType {
    case Pay
    case Subscribe
}

/// Describes the outcome of a purchase flow.
enum AppleIAPStatus: String {
    case unknown           = "Unknown"
    case orderCreationFail = "Order creation failed"
    case deviceRestricted  = "Device not allowed"
    case productNotFound   = "Product ID missing"
    case cancelled         = "Transaction cancelled"
    case alreadyOwned      = "Already purchased"
    case deferred          = "Transaction deferred"
    case verityFail        = "Verification failed"
    case veritySucceed     = "Verification succeeded"
    case renewSucceed      = "Auto-renewal succeeded"

    // Legacy raw values for backward compatibility
    static let createOrderFail = AppleIAPStatus.orderCreationFail
    static let notArrow = AppleIAPStatus.deviceRestricted
    static let noProductId = AppleIAPStatus.productNotFound
    static let failed = AppleIAPStatus.cancelled
    static let restored = AppleIAPStatus.alreadyOwned
}

typealias IAPcompletionHandle = (AppleIAPStatus, Double, ApplePayType) -> Void

// MARK: - Purchase Manager

/// Manages the complete Apple IAP lifecycle:
/// order creation → product query → payment → receipt upload → server verification.
final class AppleIAPManager: NSObject {

    static let shared = AppleIAPManager()

    var completionHandle: IAPcompletionHandle?

    private var productRequest: SKProductsRequest?
    private var retryCounters: [String: Int] = [:]
    private var cachedPurchases: [[String: String]] = []
    private var cachedSubscriptions: [[String: String]] = []
    private var pendingOrderId: String?
    private var activePayType: ApplePayType = .Pay

    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        NotificationCenter.default.addObserver(
            self, selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification, object: nil
        )
    }

    @objc private func applicationWillTerminate() {
        SKPaymentQueue.default().remove(self)
    }

    // MARK: - Public API

    /// Starts a purchase or subscription flow.
    func iap_startPurchase(productId: String, payType: ApplePayType, source: Int = 0, handle: @escaping IAPcompletionHandle) {
        loadCachedData()
        completionHandle = handle
        activePayType = payType

        let orderCreator: (@escaping (String?, Bool) -> Void) -> Void = { callback in
            switch payType {
            case .Pay:
                self.createPurchaseOrder(productId: productId, source: source, callback: callback)
            case .Subscribe:
                self.createSubscriptionOrder(productId: productId, source: source, callback: callback)
            }
        }

        orderCreator { [weak self] orderId, success in
            guard let self = self else { return }
            guard success, let orderId = orderId else {
                self.completionHandle?(.orderCreationFail, 0, payType)
                return
            }
            self.pendingOrderId = orderId
            self.fetchProduct(productId)
        }
    }

    /// Checks for and retries any unfinished transaction verifications from disk cache.
    func iap_checkUnfinishedTransactions() {
        loadCachedData()
        for entry in cachedPurchases {
            if let tid = entry["transactionId"] {
                retryCounters[tid] = 0
                verifyTransaction(tid, payType: .Pay)
            }
        }
        for entry in cachedSubscriptions {
            if let tid = entry["transactionId"] {
                retryCounters[tid] = 0
                verifyTransaction(tid, payType: .Subscribe)
            }
        }
    }
}

// MARK: - Order Creation

private extension AppleIAPManager {

    func createPurchaseOrder(productId: String, source: Int, callback: @escaping (String?, Bool) -> Void) {
        let req = NetworkRequest()
        req.endpoint = "mf/recharge/createApplePay"
        req.parameters = ["productId": productId, "source": source]
        NetworkClient.post(request: req) { ok, result, _ in
            let orderId = (result as? [String: Any])?["orderNum"] as? String
            callback(orderId, ok)
        }
    }

    func createSubscriptionOrder(productId: String, source: Int, callback: @escaping (String?, Bool) -> Void) {
        let req = NetworkRequest()
        req.endpoint = "mf/AutoSub/AppleCreateOrder"
        req.parameters = ["productId": productId, "source": source]
        NetworkClient.post(request: req) { ok, result, _ in
            let orderId = (result as? [String: Any])?["orderId"] as? String
            callback(orderId, ok)
        }
    }
}

// MARK: - Product Fetching

private extension AppleIAPManager {

    func fetchProduct(_ productId: String) {
        guard SKPaymentQueue.canMakePayments() else {
            completionHandle?(.deviceRestricted, 0, activePayType)
            return
        }
        cancelProductRequest()
        productRequest = SKProductsRequest(productIdentifiers: [productId])
        productRequest?.delegate = self
        productRequest?.start()
    }

    func cancelProductRequest() {
        productRequest?.delegate = nil
        productRequest?.cancel()
        productRequest = nil
    }
}

// MARK: - SKProductsRequestDelegate

extension AppleIAPManager: SKProductsRequestDelegate {

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard let product = response.products.first else {
            completionHandle?(.productNotFound, 0, activePayType)
            return
        }
        SKPaymentQueue.default().add(SKPayment(product: product))
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        completionHandle?(.productNotFound, 0, activePayType)
    }
}

// MARK: - SKPaymentTransactionObserver

extension AppleIAPManager: SKPaymentTransactionObserver {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for tx in transactions {
            switch tx.transactionState {
            case .purchasing:
                break

            case .purchased:
                if tx.original != nil && pendingOrderId == nil {
                    completionHandle?(.renewSucceed, 0, activePayType)
                } else if let txId = tx.transactionIdentifier {
                    retryCounters[txId] = 0
                    verifyTransaction(txId, payType: activePayType)
                }
                SKPaymentQueue.default().finishTransaction(tx)
                pendingOrderId = nil

            case .failed:
                SKPaymentQueue.default().finishTransaction(tx)
                completionHandle?(.cancelled, 0, activePayType)
                pendingOrderId = nil

            case .restored:
                SKPaymentQueue.default().finishTransaction(tx)
                completionHandle?(.alreadyOwned, 0, activePayType)
                pendingOrderId = nil

            case .deferred:
                SKPaymentQueue.default().finishTransaction(tx)
                completionHandle?(.deferred, 0, activePayType)
                pendingOrderId = nil

            @unknown default:
                SKPaymentQueue.default().finishTransaction(tx)
                completionHandle?(.unknown, 0, activePayType)
                pendingOrderId = nil
            }
        }
    }
}

// MARK: - Receipt Verification

private extension AppleIAPManager {

    func verifyTransaction(_ transactionId: String, payType: ApplePayType) {
        guard let receipt = receiptData(for: transactionId, payType: payType) else {
            completionHandle?(.verityFail, 0, payType)
            return
        }

        // Persist transaction to disk in case verification needs retry
        if let orderId = pendingOrderId {
            persistTransaction(transactionId: transactionId, orderId: orderId, receipt: receipt, payType: payType)
        }

        // Enforce retry limit
        var count = retryCounters[transactionId] ?? 0
        count += 1
        retryCounters[transactionId] = count
        if count > kMaxVerificationRetries {
            completionHandle?(.verityFail, 0, payType)
            return
        }

        // Upload receipt to server
        let cache = payType == .Pay ? cachedPurchases : cachedSubscriptions
        guard let params = cache.first(where: { $0["transactionId"] == transactionId }) else { return }

        switch payType {
        case .Pay:
            uploadPurchaseReceipt(transactionId, params: params)
        case .Subscribe:
            uploadSubscriptionReceipt(transactionId, params: params)
        }
    }

    func uploadPurchaseReceipt(_ txId: String, params: [String: String]) {
        let req = NetworkRequest()
        req.endpoint = "mf/recharge/applePayNotify"
        req.parameters = params
        NetworkClient.post(request: req) { [weak self] ok, result, error in
            guard let self = self else { return }
            guard ok || error?.code == 405 else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.verifyTransaction(txId, payType: .Pay)
                }
                return
            }
            let revenue = (result as? [String: Any])?["reportMoney"] as? Double ?? 0
            self.removeFromCache(transactionId: txId, payType: .Pay)
            self.completionHandle?(.veritySucceed, revenue, .Pay)
        }
    }

    func uploadSubscriptionReceipt(_ txId: String, params: [String: String]) {
        let req = NetworkRequest()
        req.endpoint = "mf/AutoSub/ApplePaySuccess"
        req.parameters = params
        NetworkClient.post(request: req) { [weak self] ok, result, error in
            guard let self = self else { return }
            guard ok || error?.code == 405 else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.verifyTransaction(txId, payType: .Subscribe)
                }
                return
            }
            let revenue = (result as? [String: Any])?["reportMoney"] as? Double ?? 0
            self.removeFromCache(transactionId: txId, payType: .Subscribe)
            self.completionHandle?(.veritySucceed, revenue, .Subscribe)
        }
    }
}

// MARK: - Disk Cache Management

private extension AppleIAPManager {

    func loadCachedData() {
        cachedPurchases = readCache(payType: .Pay)
        cachedSubscriptions = readCache(payType: .Subscribe)
        pendingOrderId = nil
    }

    func readCache(payType: ApplePayType) -> [[String: String]] {
        let path = cachePath(for: payType)
        guard FileManager.default.fileExists(atPath: path) else { return [] }
        if let list = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [[String: String]] {
            return list
        }
        try? FileManager.default.removeItem(atPath: path)
        return []
    }

    func persistTransaction(transactionId: String, orderId: String, receipt: String, payType: ApplePayType) {
        var cache = payType == .Pay ? cachedPurchases : cachedSubscriptions
        let isDuplicate = cache.contains { $0["transactionId"] == transactionId || $0["orderId"] == orderId }
        guard !isDuplicate else { return }

        let entry = ["transactionId": transactionId, "orderId": orderId, "verifyData": receipt]
        cache.append(entry)

        if payType == .Pay {
            cachedPurchases = cache
        } else {
            cachedSubscriptions = cache
        }
        NSKeyedArchiver.archiveRootObject(cache, toFile: cachePath(for: payType))
    }

    func removeFromCache(transactionId: String, payType: ApplePayType) {
        var cache = payType == .Pay ? cachedPurchases : cachedSubscriptions
        cache.removeAll { $0["transactionId"] == transactionId }
        NSKeyedArchiver.archiveRootObject(cache, toFile: cachePath(for: payType))

        if payType == .Pay {
            cachedPurchases = cache
        } else {
            cachedSubscriptions = cache
        }
    }

    func cachePath(for payType: ApplePayType) -> String {
        let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let dir = (docs as NSString).appendingPathComponent("App")
        if !FileManager.default.fileExists(atPath: dir) {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
        let filename = payType == .Pay ? "OrderTransactionInfo_Cache" : "OrderTransactionInfo_Subscribe_Cache"
        return (dir as NSString).appendingPathComponent(filename)
    }

    func receiptData(for transactionId: String, payType: ApplePayType) -> String? {
        let cache = payType == .Pay ? cachedPurchases : cachedSubscriptions
        if let existing = cache.first(where: { $0["transactionId"] == transactionId })?["verifyData"] {
            return existing
        }
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let data = try? Data(contentsOf: receiptURL) else {
            return nil
        }
        return data.base64EncodedString()
    }
}
