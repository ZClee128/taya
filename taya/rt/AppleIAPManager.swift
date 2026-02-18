import UIKit
import StoreKit

/// Maximum retry attempts for payment verification
let APPLE_IAP_MAX_RETRY_COUNT = 9

/// Payment type
enum ApplePayType {
    case Pay
    case Subscribe
}

/// Payment status
enum AppleIAPStatus: String {
    case unknow            = "Unknown"
    case createOrderFail   = "Order creation failed"
    case notArrow          = "Device not allowed"
    case noProductId       = "Missing product ID"
    case failed            = "Transaction failed/cancelled"
    case restored          = "Already purchased"
    case deferred          = "Transaction deferred"
    case verityFail        = "Server verification failed"
    case veritySucceed     = "Server verification succeeded"
    case renewSucceed      = "Auto-renewal succeeded"
}

typealias IAPcompletionHandle = (AppleIAPStatus, Double, ApplePayType) -> Void

class AppleIAPManager: NSObject {
    
    var completionHandle: IAPcompletionHandle?
    private var productInfoReq: SKProductsRequest?
    private var reqRetryCountDict = [String: Int]()
    private var payCacheList = [[String: String]]()
    private var subscribeCacheList = [[String: String]]()
    private var createOrderId: String?
    private var currentPayType: ApplePayType = .Pay
    
    static let shared = AppleIAPManager()
    override func copy() -> Any { return self }
    override func mutableCopy() -> Any { return self }
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self as SKPaymentTransactionObserver)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }

    @objc func appWillTerminate() {
        SKPaymentQueue.default().remove(self as SKPaymentTransactionObserver)
    }
}

// MARK: - Purchase API

extension AppleIAPManager {
    /// Create purchase order on server
    fileprivate func req_pay_createAppleOrder(productId: String, source: Int, handle: @escaping (String?, Bool) -> Void) {
        let reqModel = AppRequestModel.init()
        reqModel.requestPath = "mf/recharge/createApplePay"
        var dict = Dictionary<String, Any>()
        dict["productId"] = productId
        dict["source"] = source
        reqModel.params = dict
        AppRequestTool.startPostRequest(model: reqModel) { succeed, result, errorModel in
            guard succeed == true else {
                handle(nil, succeed)
                return
            }

            var orderId: String?
            let dict = result as? [String: Any]
            if let value = dict?["orderNum"] as? String {
                orderId = value
            }
            handle(orderId, succeed)
        }
    }
    
    /// Upload purchase receipt to server for verification
    fileprivate func req_pay_uploadAppletransaction(_ transactionId: String, params: [String: String]) {
        let reqModel = AppRequestModel.init()
        reqModel.requestPath = "mf/recharge/applePayNotify"
        reqModel.params = params
        AppRequestTool.startPostRequest(model: reqModel) { succeed, result, errorModel in
            guard succeed == true || errorModel?.errorCode == 405 else {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    self.transcationPurchasedToCheck(transactionId, .Pay)
                }
                return
            }

            let dict = result as? [String: Any]
            let reportMoney: Double = {
                if let d = dict?["reportMoney"] as? Double { return d }
                return 0
            }()
            
            let newPayCacheList = self.payCacheList.filter({$0["transactionId"] != transactionId})
            let diskPath = self.getPayCachePath()
            NSKeyedArchiver.archiveRootObject(newPayCacheList, toFile: diskPath)
                        
            self.completionHandle?(.veritySucceed, reportMoney, .Pay)
        }
    }
}

// MARK: - Subscription API

extension AppleIAPManager {
    /// Create subscription order on server
    fileprivate func req_subscribe_createAppleOrder(productId: String, source: Int, handle: @escaping (String?, Bool) -> Void) {
        let reqModel = AppRequestModel.init()
        reqModel.requestPath = "mf/AutoSub/AppleCreateOrder"
        var dict = Dictionary<String, Any>()
        dict["productId"] = productId
        dict["source"] = source
        reqModel.params = dict
        AppRequestTool.startPostRequest(model: reqModel) { succeed, result, errorModel in
            guard succeed == true else {
                handle(nil, succeed)
                return
            }

            var orderId: String? = nil
            let dict = result as? [String: Any]
            if let value = dict?["orderId"] as? String {
                orderId = value
            }
            handle(orderId, succeed)
        }
    }
    
    /// Upload subscription receipt to server for verification
    fileprivate func req_subscribe_uploadAppletransaction(_ transactionId: String, params: [String: String]) {
        let reqModel = AppRequestModel.init()
        reqModel.requestPath = "mf/AutoSub/ApplePaySuccess"
        reqModel.params = params
        AppRequestTool.startPostRequest(model: reqModel) { succeed, result, errorModel in
            guard succeed == true || errorModel?.errorCode == 405 else {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                    self.transcationPurchasedToCheck(transactionId, .Subscribe)
                }
                return
            }

            let dict = result as? [String: Any]
            let reportMoney: Double = {
                if let d = dict?["reportMoney"] as? Double { return d }
                return 0
            }()

            let newSubscribeCacheList = self.subscribeCacheList.filter({$0["transactionId"] != transactionId})
            let diskPath = self.getSubscribeCachePath()
            NSKeyedArchiver.archiveRootObject(newSubscribeCacheList, toFile: diskPath)
 
            self.completionHandle?(.veritySucceed, reportMoney, .Subscribe)
        }
    }
}

// MARK: - Transaction Data Management

extension AppleIAPManager {
    /// Initialize payment data from disk cache
    private func iap_initData() {
        self.payCacheList = getLocalPayCacheList(payType: .Pay)
        self.subscribeCacheList = getLocalPayCacheList(payType: .Subscribe)
        self.createOrderId = nil
    }
    
    /// Load cached transaction list from disk
    private func getLocalPayCacheList(payType: ApplePayType) -> [[String: String]] {
        var list: [[String: String]]?
        var diskPath = ""
        if payType == .Pay {
            diskPath = getPayCachePath()
        } else {
            diskPath = getSubscribeCachePath()
        }
        
        if FileManager.default.fileExists(atPath: diskPath) {
            list = NSKeyedUnarchiver.unarchiveObject(withFile: diskPath) as? [[String: String]]
            if list == nil {
               try? FileManager.default.removeItem(atPath: diskPath)
            }
        }
        if list == nil {
            list = [[String: String]]()
        }
        return list!
    }
    
    /// Get purchase cache file path
    private func getPayCachePath() -> String {
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let appDirectoryPath = (documentDirectoryPath as NSString).appendingPathComponent("App")
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: appDirectoryPath) == false {
           try? fileManager.createDirectory(atPath: appDirectoryPath, withIntermediateDirectories: true)
        }
    
        let filePath = (appDirectoryPath as NSString).appendingPathComponent("OrderTransactionInfo_Cache")
        return filePath
    }
    
    /// Get subscription cache file path
    private func getSubscribeCachePath() -> String {
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let appDirectoryPath = (documentDirectoryPath as NSString).appendingPathComponent("App")
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: appDirectoryPath) == false {
           try? fileManager.createDirectory(atPath: appDirectoryPath, withIntermediateDirectories: true)
        }
    
        let filePath = (appDirectoryPath as NSString).appendingPathComponent("OrderTransactionInfo_Subscribe_Cache")
        return filePath
    }
 
    /// Get receipt data for server verification
    fileprivate func getVerifyData(_ transactionId: String, _ payType: ApplePayType) -> String? {
        var paramsArr = [[String: String]]()
        switch(payType) {
        case .Pay:
            paramsArr = self.payCacheList.filter({$0["transactionId"] == transactionId})
        case .Subscribe:
            paramsArr = self.subscribeCacheList.filter({$0["transactionId"] == transactionId})
        }
        if paramsArr.count > 0 && paramsArr.first!["verifyData"] != nil {
            return paramsArr.first!["verifyData"]
        }

        guard let receiptUrl = Bundle.main.appStoreReceiptURL else { return nil }
        let data = NSData(contentsOf: receiptUrl)
        let receiptStr = data?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        return receiptStr
    }
}

// MARK: - Retry Logic

extension AppleIAPManager {
    /// Check for unfinished transactions and retry verification
    func iap_checkUnfinishedTransactions() {
        iap_initData()

        for dict in self.payCacheList {
            iap_failedRetry(dict["transactionId"], .Pay)
        }
        
        for dict in self.subscribeCacheList {
            iap_failedRetry(dict["transactionId"], .Subscribe)
        }
    }
    
    /// Retry failed verification
    private func iap_failedRetry(_ transactionId: String?, _ payType: ApplePayType) {
        guard let transactionId = transactionId else { return }
        reqRetryCountDict[transactionId] = 0
        transcationPurchasedToCheck(transactionId, payType)
    }
}

// MARK: - Payment Flow

extension AppleIAPManager {
    /// Start Apple payment flow: create order → query product → pay → verify
    func iap_startPurchase(productId: String, payType: ApplePayType, source: Int = 0, handle: @escaping IAPcompletionHandle) {
        iap_initData()
        self.completionHandle = handle
        self.currentPayType = payType
        
        switch(payType) {
        case .Pay:
            req_pay_createAppleOrder(productId: productId, source: source) { [weak self] orderId, succeed in
                guard let self = self else { return }
                guard succeed == true && orderId != nil else {
                    self.completionHandle?(.createOrderFail, 0, .Pay)
                    return
                }
                
                self.createOrderId = orderId
                self.requestProductInfo(productId)
            }
        
        case .Subscribe:
            req_subscribe_createAppleOrder(productId: productId, source: source) { [weak self] orderId, succeed in
                guard let self = self else { return }
                guard succeed == true && orderId != nil else {
                    self.completionHandle?(.createOrderFail, 0, .Subscribe)
                    return
                }
                
                self.createOrderId = orderId
                self.requestProductInfo(productId)
            }
        }
    }
        
    /// Query Apple product info and initiate payment
    fileprivate func requestProductInfo(_ productId: String) {
        guard SKPaymentQueue.canMakePayments() else {
            self.completionHandle?(.notArrow, 0, currentPayType)
            return
        }
        
        self.clearProductInfoRequest()
        let identifiers: Set<String> = [productId]
        productInfoReq = SKProductsRequest(productIdentifiers: identifiers)
        productInfoReq?.delegate = self
        productInfoReq?.start()
    }
    
    /// Cancel current product info request
    fileprivate func clearProductInfoRequest() {
        guard productInfoReq != nil else { return }
        productInfoReq?.delegate = nil
        productInfoReq?.cancel()
        productInfoReq = nil
    }
}

// MARK: - SKProductsRequestDelegate

extension AppleIAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
         guard response.products.count > 0 else {
             self.completionHandle?( .noProductId, 0, currentPayType)
             return
         }
         
         let payment = SKPayment(product: response.products.first!)
         SKPaymentQueue.default().add(payment)
     }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.completionHandle?( .noProductId, 0, currentPayType)
    }
    
    func requestDidFinish(_ request: SKRequest) {
        
    }
}

// MARK: - SKPaymentTransactionObserver

extension AppleIAPManager: SKPaymentTransactionObserver {
    /// Handle Apple payment transaction updates
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                break
                
            case .purchased:
                if transaction.original != nil && createOrderId == nil {
                    // Auto-renewal: no need to call server verification
                    self.completionHandle?(.renewSucceed, 0, currentPayType)
                } else {
                    reqRetryCountDict[transaction.transactionIdentifier!] = 0
                    transcationPurchasedToCheck(transaction.transactionIdentifier!, self.currentPayType)
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                createOrderId = nil
                
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                self.completionHandle?(.failed, 0, currentPayType)
                createOrderId = nil

            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                self.completionHandle?(.restored, 0, currentPayType)
                createOrderId = nil
                
            case .deferred:
                SKPaymentQueue.default().finishTransaction(transaction)
                self.completionHandle?(.deferred, 0, currentPayType)
                createOrderId = nil
                
            @unknown default:
                SKPaymentQueue.default().finishTransaction(transaction)
                self.completionHandle?(.unknow, 0, currentPayType)
                createOrderId = nil
                fatalError("Unknown transaction type")
            }
        }
    }
 
    /// Server-side receipt verification flow
    fileprivate func transcationPurchasedToCheck(_ transactionId: String, _ payType: ApplePayType) {
        guard let receiptStr = getVerifyData(transactionId, payType) else {
            self.completionHandle?(.verityFail, 0, payType)
            return
        }

        // Cache payment info to prevent data loss on verification failure
        if createOrderId != nil {
            switch(payType) {
            case .Pay:
                if self.payCacheList.filter({$0["transactionId"] == transactionId || $0["orderId"] == createOrderId}).count == 0 {
                    let cacheDict = ["transactionId": transactionId,
                                     "orderId": createOrderId!,
                                     "verifyData": receiptStr]
                    self.payCacheList.append(cacheDict)
                    let diskPath = self.getPayCachePath()
                    NSKeyedArchiver.archiveRootObject(self.payCacheList, toFile: diskPath)
                }
                
            case .Subscribe:
                if self.subscribeCacheList.filter({$0["transactionId"] == transactionId || $0["orderId"] == createOrderId}).count == 0 {
                    let cacheDict = ["transactionId": transactionId,
                                     "orderId": createOrderId!,
                                     "verifyData": receiptStr]
                    self.subscribeCacheList.append(cacheDict)
                    let diskPath = self.getSubscribeCachePath()
                    NSKeyedArchiver.archiveRootObject(self.subscribeCacheList, toFile: diskPath)
                }
            }
        }
        
        // Limit retry count per transaction
        var reqCount = reqRetryCountDict[transactionId] ?? 0
        reqCount += 1
        reqRetryCountDict[transactionId] = reqCount
        if reqCount > APPLE_IAP_MAX_RETRY_COUNT {
            self.completionHandle?(.verityFail, 0, payType)
            return
        }
        
        // Send receipt to server for verification
        switch(payType) {
        case .Pay:
            let paramsArr = self.payCacheList.filter({$0["transactionId"] == transactionId})
            guard paramsArr.count > 0 else { return }
            req_pay_uploadAppletransaction(transactionId, params: paramsArr.first!)
            
        case .Subscribe:
            let paramsArr = self.subscribeCacheList.filter({$0["transactionId"] == transactionId})
            guard paramsArr.count > 0 else { return }
            req_subscribe_uploadAppletransaction(transactionId, params: paramsArr.first!)
        }
    }
}
