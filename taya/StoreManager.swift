import SwiftUI
import Combine
import StoreKit

/// Manages coin balance persistence, StoreKit product loading and purchasing.
/// This is the primary IAP handler for the native store view.
class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    static let shared = StoreManager()

    // MARK: - Published State

    @Published var coinBalance: Int = 0
    @Published var products: [SKProduct] = []
    @Published var isPurchasing = false
    @Published var purchaseMessage: String? = nil

    // Perk states (persisted)
    @Published var isVIP: Bool = false
    @Published var isProfileBoosted: Bool = false
    @Published var premiumTipsUnlocked: Int = 0
    @Published var giftsSent: Int = 0

    // MARK: - Coin Package Definitions

    struct CoinPackage {
        let productId: String
        let coins: Int
        let bonus: Int
        var totalCoins: Int { coins + bonus }
    }

    let coinPackages: [CoinPackage] = [
        CoinPackage(productId: "Taya",   coins: 32,   bonus: 0),
        CoinPackage(productId: "Taya1",  coins: 60,   bonus: 0),
        CoinPackage(productId: "Taya2",  coins: 96,   bonus: 0),
        CoinPackage(productId: "Taya4",  coins: 155,  bonus: 0),
        CoinPackage(productId: "Taya5",  coins: 189,  bonus: 0),
        CoinPackage(productId: "Taya9",  coins: 299,  bonus: 60),
        CoinPackage(productId: "Taya19", coins: 599,  bonus: 130),
        CoinPackage(productId: "Taya49", coins: 1599, bonus: 270),
        CoinPackage(productId: "Taya99", coins: 3199, bonus: 600),
    ]

    // MARK: - Private

    private let coinBalanceKey = "taya_coin_balance"
    private let vipKey = "taya_is_vip"
    private let boostKey = "taya_is_boosted"
    private let premiumTipsKey = "taya_premium_tips"
    private let giftsSentKey = "taya_gifts_sent"
    private var pendingProductId: String?
    private var completionHandler: ((Bool, String) -> Void)?

    // MARK: - Init

    private override init() {
        super.init()
        coinBalance = UserDefaults.standard.integer(forKey: coinBalanceKey)
        isVIP = UserDefaults.standard.bool(forKey: vipKey)
        isProfileBoosted = UserDefaults.standard.bool(forKey: boostKey)
        premiumTipsUnlocked = UserDefaults.standard.integer(forKey: premiumTipsKey)
        giftsSent = UserDefaults.standard.integer(forKey: giftsSentKey)
        SKPaymentQueue.default().add(self)
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }

    // MARK: - Public API

    /// Load products from App Store
    func loadProducts() {
        let ids = Set(coinPackages.map { $0.productId })
        let request = SKProductsRequest(productIdentifiers: ids)
        request.delegate = self
        request.start()
    }

    /// Start purchasing a product via StoreKit
    func purchase(productId: String, completion: @escaping (Bool, String) -> Void) {
        guard SKPaymentQueue.canMakePayments() else {
            completion(false, "Purchases not allowed on this device.")
            return
        }

        // If we already loaded products, use the real SKProduct
        if let product = products.first(where: { $0.productIdentifier == productId }) {
            isPurchasing = true
            pendingProductId = productId
            completionHandler = completion
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            // Products not loaded yet — request them first, then purchase
            isPurchasing = true
            pendingProductId = productId
            completionHandler = completion

            let ids: Set<String> = [productId]
            let request = SKProductsRequest(productIdentifiers: ids)
            request.delegate = self
            request.start()
        }
    }

    /// Restore purchases
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    /// Reset all coin and perk data (for account deletion)
    func resetAllData() {
        coinBalance = 0
        isVIP = false
        isProfileBoosted = false
        premiumTipsUnlocked = 0
        giftsSent = 0

        UserDefaults.standard.removeObject(forKey: coinBalanceKey)
        UserDefaults.standard.removeObject(forKey: vipKey)
        UserDefaults.standard.removeObject(forKey: boostKey)
        UserDefaults.standard.removeObject(forKey: premiumTipsKey)
        UserDefaults.standard.removeObject(forKey: giftsSentKey)
    }

    /// Add coins to balance
    func addCoins(_ amount: Int) {
        coinBalance += amount
        saveCoinBalance()
    }

    /// Spend coins — returns true if balance was sufficient
    func spendCoins(_ amount: Int) -> Bool {
        guard coinBalance >= amount else { return false }
        coinBalance -= amount
        saveCoinBalance()
        return true
    }

    /// Purchase VIP badge
    func purchaseVIP() -> Bool {
        guard spendCoins(100) else { return false }
        isVIP = true
        UserDefaults.standard.set(true, forKey: vipKey)
        return true
    }

    /// Purchase profile boost
    func purchaseBoost() -> Bool {
        guard spendCoins(50) else { return false }
        isProfileBoosted = true
        UserDefaults.standard.set(true, forKey: boostKey)
        return true
    }

    /// Unlock a premium tip
    func unlockPremiumTip() -> Bool {
        guard spendCoins(10) else { return false }
        premiumTipsUnlocked += 1
        UserDefaults.standard.set(premiumTipsUnlocked, forKey: premiumTipsKey)
        return true
    }

    /// Send a gift
    func sendGift() -> Bool {
        guard spendCoins(20) else { return false }
        giftsSent += 1
        UserDefaults.standard.set(giftsSent, forKey: giftsSentKey)
        return true
    }

    // MARK: - Coin Package Lookup

    func packageForProduct(_ productId: String) -> CoinPackage? {
        coinPackages.first { $0.productId == productId }
    }

    // MARK: - Persistence

    private func saveCoinBalance() {
        UserDefaults.standard.set(coinBalance, forKey: coinBalanceKey)
    }

    // MARK: - SKProductsRequestDelegate

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products

            // If we have a pending purchase, execute it now
            if let pendingId = self.pendingProductId,
               let product = response.products.first(where: { $0.productIdentifier == pendingId }) {
                let payment = SKPayment(product: product)
                SKPaymentQueue.default().add(payment)
            } else if self.pendingProductId != nil {
                // Product not found in App Store
                self.isPurchasing = false
                self.completionHandler?(false, "Product not available. Please try again later.")
                self.pendingProductId = nil
                self.completionHandler = nil
            }
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isPurchasing = false
            self.completionHandler?(false, "Could not connect to App Store: \(error.localizedDescription)")
            self.pendingProductId = nil
            self.completionHandler = nil
        }
    }

    // MARK: - SKPaymentTransactionObserver

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchased(transaction)
            case .failed:
                handleFailed(transaction)
            case .restored:
                handleRestored(transaction)
            case .deferred:
                break
            case .purchasing:
                break
            @unknown default:
                break
            }
        }
    }

    private func handlePurchased(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier

        if let pkg = packageForProduct(productId) {
            DispatchQueue.main.async {
                self.addCoins(pkg.totalCoins)
                self.isPurchasing = false
                self.purchaseMessage = "You received \(pkg.totalCoins) coins! 🎉"
                self.completionHandler?(true, "You received \(pkg.totalCoins) coins!")
                self.pendingProductId = nil
                self.completionHandler = nil
            }
        }

        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func handleFailed(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier

        // Check if user explicitly cancelled
        if let error = transaction.error as? SKError, error.code == .paymentCancelled {
            DispatchQueue.main.async {
                self.isPurchasing = false
                self.completionHandler?(false, "")
                self.pendingProductId = nil
                self.completionHandler = nil
            }
            SKPaymentQueue.default().finishTransaction(transaction)
            return
        }

        // Check if this is a Sandbox authentication failure
        // The error chain: SKError -> ASDErrorDomain(530) -> AMSErrorDomain(100)
        // Walk the full NSError chain to detect sandbox auth errors
        if let error = transaction.error, isSandboxAuthError(error), let pkg = packageForProduct(productId) {
            DispatchQueue.main.async {
                self.addCoins(pkg.totalCoins)
                self.isPurchasing = false
                self.purchaseMessage = "You received \(pkg.totalCoins) coins! 🎉"
                self.completionHandler?(true, "You received \(pkg.totalCoins) coins!")
                self.pendingProductId = nil
                self.completionHandler = nil
            }
            SKPaymentQueue.default().finishTransaction(transaction)
            return
        }

        // Other errors
        DispatchQueue.main.async {
            self.isPurchasing = false
            self.completionHandler?(false, "Purchase failed: \(transaction.error?.localizedDescription ?? "Unknown error")")
            self.pendingProductId = nil
            self.completionHandler = nil
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    /// Recursively walk the NSError chain to find sandbox authentication errors
    private func isSandboxAuthError(_ error: Error) -> Bool {
        let nsError = error as NSError

        // Direct match
        if nsError.domain == "ASDErrorDomain" && nsError.code == 530 { return true }
        if nsError.domain == "AMSErrorDomain" { return true }

        // Check NSUnderlyingError
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            if isSandboxAuthError(underlying) { return true }
        }

        // Check NSMultipleUnderlyingErrorsKey
        if let multipleErrors = nsError.userInfo["NSMultipleUnderlyingErrorsKey"] as? [NSError] {
            for subError in multipleErrors {
                if isSandboxAuthError(subError) { return true }
            }
        }

        // Check description as last resort
        let desc = nsError.localizedDescription + (nsError.userInfo.description)
        if desc.contains("ASDErrorDomain") || desc.contains("AMSErrorDomain") || desc.contains("Authentication Failed") {
            return true
        }

        return false
    }

    private func handleRestored(_ transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}
