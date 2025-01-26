//
//  PurchaseView.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import RevenueCat
import SwiftUI

@MainActor
class PurchaseViewModel: NSObject, ObservableObject {
    @Published private(set) var currentOffering: Offering?
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var purchaseError: String?
    @Published var isLoading = false
    
    override init() {
        super.init()
        // 设置代理以接收更新
        Purchases.shared.delegate = self
        
        // 获取当前用户状态
        Task {
            await updateCustomerInfo()
        }
    }
    
    func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let offerings = try await Purchases.shared.offerings()
            // 使用指定的 offering identifier
            currentOffering = offerings.offering(identifier: "plus") ?? offerings.current
        } catch {
            purchaseError = error.localizedDescription
        }
    }
    
    func purchase(_ package: Package) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            customerInfo = result.customerInfo
            // 处理购买成功
        } catch {
            purchaseError = error.localizedDescription
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            customerInfo = try await Purchases.shared.restorePurchases()
        } catch {
            purchaseError = error.localizedDescription
        }
    }
    
    private func updateCustomerInfo() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            purchaseError = error.localizedDescription
        }
    }
}

// MARK: - PurchasesDelegate
extension PurchaseViewModel: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
        }
    }
}

struct PurchaseView: View {
    @StateObject private var viewModel = PurchaseViewModel()
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("NeoDB+")
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
                    
                    // Subscription Plans
                    VStack(spacing: 16) {
                        if let offering = viewModel.currentOffering {
                            ForEach(offering.availablePackages.sorted { $0.storeProduct.price < $1.storeProduct.price }, id: \.identifier) { package in
                                Button {
                                    Task {
                                        await viewModel.purchase(package)
                                    }
                                } label: {
                                    PackageView(package: package)
                                }
                                .disabled(viewModel.isLoading)
                            }
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Legal Links
                    HStack(spacing: 16) {
                        Button("Terms of Service") {
                            openURL(StoreConfig.URLs.termsOfService)
                        }
                        Button("Privacy Policy") {
                            openURL(StoreConfig.URLs.privacyPolicy)
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
                            await viewModel.restorePurchases()
                        }
                    }
                }
            }
            .task {
                await viewModel.loadOfferings()
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

struct PackageView: View {
    let package: Package
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.storeProduct.localizedTitle)
                        .font(.headline)
                    if package.packageType == .lifetime {
                        Text("One-time Purchase")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(package.storeProduct.localizedDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if package.packageType != .lifetime {
                        Text(package.packageType == .annual ? "per year" : "per month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    PurchaseView()
} 
