import SwiftUI
import StoreKit

/// Store page — coin purchase with real StoreKit IAP flow.
/// Shows coin balance, product list, and handles purchase via StoreManager.
struct StoreView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var storeManager = StoreManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showResult = false
    @State private var resultMessage = ""

    private let accentGreen = Color(red: 0.36, green: 0.72, blue: 0.66)
    private let goldColor = Color(red: 1.0, green: 0.78, blue: 0.18)

    // Display-only info (prices from App Store Connect)
    private let displayPackages: [(id: String, price: String, coins: Int, bonus: Int)] = [
        ("Taya",   "$0.99",  32,   0),
        ("Taya1",  "$1.99",  60,   0),
        ("Taya2",  "$2.99",  96,   0),
        ("Taya4",  "$4.99",  155,  0),
        ("Taya6",  "$5.99",  189,  0),
        ("Taya9",  "$9.99",  299,  60),
        ("Taya19", "$19.99", 599,  130),
        ("Taya49", "$49.99", 1599, 270),
        ("Taya99", "$99.99", 3199, 600),
    ]

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    balanceSection
                    coinListSection
                    restoreSection
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitle("Store")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            storeManager.loadProducts()
        }
        .alert(isPresented: $showResult) {
            Alert(title: Text(resultMessage), dismissButton: .default(Text("OK")))
        }
        .onReceive(storeManager.$purchaseMessage) { msg in
            if let msg = msg, !msg.isEmpty {
                resultMessage = msg
                showResult = true
                storeManager.purchaseMessage = nil
            }
        }
    }

    // MARK: - Balance

    private var balanceSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(goldColor)
                .padding(.top, 16)
            Text("\(storeManager.coinBalance)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("coins")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    // MARK: - Coin List

    private var coinListSection: some View {
        VStack(spacing: 10) {
            Text("Get Coins")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(displayPackages, id: \.id) { pkg in
                coinRow(pkg)
            }
        }
        .padding(.horizontal)
    }

    private func coinRow(_ pkg: (id: String, price: String, coins: Int, bonus: Int)) -> some View {
        let totalCoins = pkg.coins + pkg.bonus

        return Button(action: {
            purchaseProduct(pkg.id)
        }) {
            HStack(spacing: 12) {
                // Coin icon
                ZStack {
                    Circle()
                        .fill(goldColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(goldColor)
                }

                // Coin info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(totalCoins)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("coins")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if pkg.bonus > 0 {
                        Text("\(pkg.coins) + \(pkg.bonus) bonus")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                // HOT badge
                if pkg.id == "Taya9" || pkg.id == "Taya19" {
                    Text("HOT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                }

                // Price from App Store if loaded, otherwise fallback
                Text(priceForProduct(pkg.id) ?? pkg.price)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accentGreen)
                    .cornerRadius(20)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(storeManager.isPurchasing)
        .opacity(storeManager.isPurchasing ? 0.6 : 1.0)
    }

    // MARK: - Restore

    private var restoreSection: some View {
        VStack(spacing: 8) {
            if storeManager.isPurchasing {
                HStack {
                    Spacer()
                    Text("Processing purchase...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            Button(action: {
                storeManager.restorePurchases()
            }) {
                Text("Restore Purchases")
                    .font(.caption)
                    .foregroundColor(accentGreen)
            }
        }
    }

    // MARK: - Helpers

    /// Get localized price string from loaded SKProducts
    private func priceForProduct(_ productId: String) -> String? {
        guard let product = storeManager.products.first(where: { $0.productIdentifier == productId }) else {
            return nil
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price)
    }

    private func purchaseProduct(_ productId: String) {
        ProgressHUD.show()
        storeManager.purchase(productId: productId) { success, message in
            ProgressHUD.dismiss()
            if !message.isEmpty {
                self.resultMessage = message
                self.showResult = true
            }
        }
    }
}
