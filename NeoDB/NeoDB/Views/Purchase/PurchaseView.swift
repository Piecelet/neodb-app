//
//  PurchaseView.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import StoreKit
import SwiftUI

@MainActor
class PurchaseViewModel: ObservableObject {
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchaseError: String?
    @Published var isLoading = false
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let products = try await Product.products(for: StoreConfig.subscriptionIds)
            subscriptions = products.sorted { $0.price < $1.price }
        } catch {
            purchaseError = error.localizedDescription
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // 处理购买成功
            break
        case .pending:
            // 等待用户确认购买
            break
        case .userCancelled:
            // 用户取消购买
            break
        @unknown default:
            break
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
    }
}

struct PurchaseView: View {
    @StateObject private var viewModel = PurchaseViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Piecelet+")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock premium features and supercharge your tracking experience.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Feature List
                    VStack(spacing: 16) {
                        featureRow(
                            icon: "person.2",
                            title: "Multiple Accounts",
                            description: "Connect and switch between multiple NeoDB accounts seamlessly."
                        )
                        
                        featureRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Cross-platform Sync",
                            description: "Sync your marks with Trakt and other platforms. (Coming soon)",
                            isComingSoon: true
                        )
                        
                        featureRow(
                            icon: "magnifyingglass",
                            title: "Enhanced Search",
                            description: "Access additional search sources for better results. (Coming soon)",
                            isComingSoon: true
                        )
                        
                        featureRow(
                            icon: "arrow.left.arrow.right",
                            title: "Quick Actions",
                            description: "Quickly search and open items in Douban. (Coming soon)",
                            isComingSoon: true
                        )
                        
                        featureRow(
                            icon: "bell",
                            title: "Series Updates",
                            description: "Track and get notified about series updates. (Coming soon)",
                            isComingSoon: true
                        )
                        
                        featureRow(
                            icon: "checklist",
                            title: "Batch Actions",
                            description: "Mark multiple items at once efficiently. (Coming soon)",
                            isComingSoon: true
                        )
                    }
                    .padding(.horizontal)
                    
                    // Show all plans button
                    NavigationLink {
                        plansView
                    } label: {
                        Text("Show all plans")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Trial Button
                    if let yearlyProduct = viewModel.subscriptions.first {
                        Button {
                            Task {
                                try await viewModel.purchase(yearlyProduct)
                            }
                        } label: {
                            Text("Try Free For 7 Days")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.black)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        
                        // Price Info
                        Text("Then \(yearlyProduct.displayPrice) per year • Cancel anytime")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if viewModel.isLoading {
                        ProgressView()
                    }
                    
                    // Legal Links
                    HStack(spacing: 16) {
                        Button("Terms of Service") {
                            openURL(StoreConfig.termsURL)
                        }
                        Button("Privacy Policy") {
                            openURL(StoreConfig.privacyURL)
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Preferences")
                        .font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Restore") {
                        Task {
                            try await viewModel.restorePurchases()
                        }
                    }
                }
            }
            .task {
                await viewModel.loadProducts()
            }
            .alert("Purchase Error", isPresented: .constant(viewModel.purchaseError != nil)) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.purchaseError {
                    Text(error)
                }
            }
        }
    }
    
    private var plansView: some View {
        List {
            ForEach(viewModel.subscriptions) { product in
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        Task {
                            try await viewModel.purchase(product)
                        }
                    } label: {
                        Text("Subscribe for \(product.displayPrice)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.black)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Subscription Plans")
        .listStyle(.insetGrouped)
    }
    
    private func featureRow(icon: String, title: String, description: String, isComingSoon: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 32, height: 32)
                .foregroundStyle(isComingSoon ? Color.secondary.opacity(0.6) : .secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(isComingSoon ? Color.primary.opacity(0.8) : .primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(isComingSoon ? Color.secondary.opacity(0.6) : .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isComingSoon ? 0.8 : 1)
    }
}

#Preview {
    PurchaseView()
} 
