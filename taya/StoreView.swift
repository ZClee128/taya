//
//  StoreView.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import SwiftUI

struct StoreView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var storeManager = StoreManager()
    @Environment(\.presentationMode) var presentationMode
    
    // Grid Setup
    let columns = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Balance
                HStack {
                    VStack(alignment: .leading) {
                        Text("My Balance")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.yellow)
                            Text("\(sessionManager.coinBalance)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                
                Divider()

                // Product Grid (Simulating Grid for iOS 13 using VStack/HStack)
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(gridRows(products: storeManager.displayProducts), id: \.self) { rowProducts in
                            HStack(spacing: 15) {
                                ForEach(rowProducts) { product in
                                    Button(action: {
                                        storeManager.purchaseProduct(mockProduct: product)
                                    }) {
                                        VStack(spacing: 8) {
                                            Text(product.title)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                            
                                            if !product.description.isEmpty {
                                                Text(product.description)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)
                                                    .frame(height: 30) // Fixed height for alignment
                                            }
                                            
                                            Text(product.price)
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue)
                                                .cornerRadius(15)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(UIColor.systemBackground))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    }
                                }
                                // Fill empty spaces
                                ForEach(0..<(columns - rowProducts.count), id: \.self) { _ in
                                    Color.clear.frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitle("Store 🛒", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .disabled(storeManager.isLoading)
            .onAppear {
                // Bind Callbacks
                storeManager.onPurchaseSuccess = { coins in
                    sessionManager.addCoins(coins)
                }
                // Failure needs no action besides stopping loading (handled in manager)
            }
            .overlay(
                Group {
                    if storeManager.isLoading {
                        Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                        VStack {
                            Text("Processing...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                    }
                }
            )
        }
    }
    
    // Helper for Mock Product Grid
    func gridRows(products: [StoreManager.MockProduct]) -> [[StoreManager.MockProduct]] {
        var rows: [[StoreManager.MockProduct]] = []
        for i in stride(from: 0, to: products.count, by: columns) {
            var row: [StoreManager.MockProduct] = []
            for j in 0..<columns {
                if i + j < products.count {
                    row.append(products[i + j])
                }
            }
            rows.append(row)
        }
        return rows
    }
}

struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreView(sessionManager: SessionManager())
    }
}
