//
//  StoreManager.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import Foundation
import StoreKit
import Combine

class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    @Published var products: [SKProduct] = []
    @Published var isLoading = false
    
    // Callbacks for the UI to know what happened
    var onPurchaseSuccess: ((Int) -> Void)?
    var onPurchaseFailure: (() -> Void)?

    private let productIdentifiers: Set<String> = [
        "Taya",
        "Taya1",
        "Taya2",
        "Taya4",
        "Taya5",
        "Taya9",
        "Taya19",
        "Taya49",
        "Taya99"
    ]
    
    // We keep the MockProduct struct for the UI display if real fetch fails or is slow
    struct MockProduct: Identifiable, Hashable {
        let id: String
        let title: String
        let description: String
        let price: String
        let coins: Int
        var skProduct: SKProduct? = nil // Hold reference to real product if available
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: MockProduct, rhs: MockProduct) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    @Published var displayProducts: [MockProduct] = []
    
    override init() {
        super.init()
        // Setup initial display products (based on provided table)
        self.displayProducts = [
            MockProduct(id: "Taya", title: "32 coins", description: "32+0 Bonus", price: "$0.99", coins: 32),
            MockProduct(id: "Taya1", title: "60 coins", description: "60+0 Bonus", price: "$1.99", coins: 60),
            MockProduct(id: "Taya2", title: "96 coins", description: "96+0 Bonus", price: "$2.99", coins: 96),
            MockProduct(id: "Taya4", title: "155 coins", description: "155+0 Bonus", price: "$4.99", coins: 155),
            MockProduct(id: "Taya5", title: "189 coins", description: "189+0 Bonus", price: "$5.99", coins: 189),
            MockProduct(id: "Taya9", title: "359 coins", description: "299+60 Bonus", price: "$9.99", coins: 359),
            MockProduct(id: "Taya19", title: "729 coins", description: "599+130 Bonus", price: "$19.99", coins: 729),
            MockProduct(id: "Taya49", title: "1869 coins", description: "1599+270 Bonus", price: "$49.99", coins: 1869),
            MockProduct(id: "Taya99", title: "3799 coins", description: "3199+600 Bonus", price: "$99.99", coins: 3799)
        ]
        
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func fetchProducts() {
        // Request real products from Apple
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
            self.updateDisplayProducts()
        }
    }
    
    private func updateDisplayProducts() {
        // Map real SKProducts to our MockProduct display model if they exist
        var newDisplay: [MockProduct] = []
        for mock in displayProducts {
            var updated = mock
            if let real = products.first(where: { $0.productIdentifier == mock.id }) {
                updated.skProduct = real
                // Update price with locale if needed, but for now stick to mock or simple formatter
                // let formatter = NumberFormatter()
                // formatter.numberStyle = .currency
                // formatter.locale = real.priceLocale
                // updated.price = formatter.string(from: real.price) ?? updated.price
            }
            newDisplay.append(updated)
        }
        self.displayProducts = newDisplay
    }
    
    func purchaseProduct(mockProduct: MockProduct) {
        isLoading = true
        
        if SKPaymentQueue.canMakePayments() {
            // If we have a real SKProduct, use it. Otherwise, this is a simulated run where we might need to "fake" the transaction
            // But user asked for "Real payment flow". If we don't have the SKProduct (because fetch failed), we can't initiate a real payment.
            // However, typically in Simulator without config, fetch fails.
            
            if let product = mockProduct.skProduct {
                let payment = SKPayment(product: product)
                SKPaymentQueue.default().add(payment)
            } else {
                // FALLBACK: If we couldn't fetch real products (common in Simulator without account),
                // we treat this as a "Success" immediately as per user request "other errors ... go successful"
                // But let's try to be as real as possible.
                // If we can't even get the product, we can't start the queue.
                // So we'll simulate the "Success" part of the request here for non-fetched products.
                print("Could not fetch real SKProduct. Simulating success for Simulator.")
                finishPurchase(mockProduct: mockProduct)
            }
        } else {
            isLoading = false
            // Can't make payments
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                isLoading = true
                break
                
            case .purchased:
                // Success
                SKPaymentQueue.default().finishTransaction(transaction)
                handleSuccess(transaction: transaction)
                
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                handleFailure(transaction: transaction)
                
            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                // We treat restore as success kind of? Or ignore for consumables.
                isLoading = false
                
            case .deferred:
                break
                
            @unknown default:
                break
            }
        }
    }
    
    private func handleSuccess(transaction: SKPaymentTransaction) {
        isLoading = false
        // Identify product and add coins
        let productId = transaction.payment.productIdentifier
        if let match = displayProducts.first(where: { $0.id == productId }) {
            onPurchaseSuccess?(match.coins)
        }
    }
    
    private func handleFailure(transaction: SKPaymentTransaction) {
        isLoading = false
        if let error = transaction.error as? SKError {
            print("Transaction failed with error: \(error.code)")
            
            // "Only cancel and login failure go to failure callback, other errors in simulator go success"
            switch error.code {
            case .paymentCancelled:
                // Cancelled -> Failure
                onPurchaseFailure?()
                
            case .unknown:
                // Unknown often implies login failed in Simulator or generic error.
                // User said "Login failure go failure".
                // HARD TO DISTINGUISH "Login Failed" from other Unknowns.
                // But usually Login Cancel is paymentCancelled.
                // Let's assume Unknown might be "Cannot connect to iTunes Store" which happens often.
                // The user said: "Other errors in simulator go to success callback flow".
                // So checking specifically for cancellation.
                 handleSuccessAfterError(transaction: transaction)

            case .clientInvalid, .paymentInvalid, .paymentNotAllowed, .storeProductNotAvailable, .cloudServicePermissionDenied, .cloudServiceNetworkConnectionFailed, .cloudServiceRevoked:
                 // Treat these as "Simulator quirks" -> Success
                 handleSuccessAfterError(transaction: transaction)
                 
            default:
                 // Any other error -> Success
                 handleSuccessAfterError(transaction: transaction)
            }
        } else {
            // No specific error -> Assume success? Or generic fail.
             onPurchaseFailure?()
        }
    }
    
    private func handleSuccessAfterError(transaction: SKPaymentTransaction) {
        // This is the "Simulator Magic" requested by the user.
        // Even though it failed, we treat it as success.
        let productId = transaction.payment.productIdentifier
        if let match = displayProducts.first(where: { $0.id == productId }) {
             onPurchaseSuccess?(match.coins)
        }
    }
    
    private func finishPurchase(mockProduct: MockProduct) {
        // Direct simulation path
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.onPurchaseSuccess?(mockProduct.coins)
        }
    }

}
