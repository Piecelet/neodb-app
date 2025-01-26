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
                        Text("Piecelet+")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock a richer experience for your NeoDB journey")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Feature List
                    VStack(spacing: 16) {
                        ForEach(StoreConfig.features) { feature in
                            featureRow(feature: feature)
                        }
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
            .safeAreaInset(edge: .bottom) {
                
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
                    .background(.bar)
                    .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
    
    private func featureRow(feature: StoreConfig.Feature) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title2)
                .frame(width: 32, height: 32)
                .foregroundStyle(feature.color)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(feature.title)
                        .font(.headline)
                        .foregroundStyle(feature.isComingSoon ? Color.primary.opacity(0.8) : .primary)
                    
                    if feature.isComingSoon {
                        Text("Coming Soon")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(feature.isComingSoon ? Color.secondary.opacity(0.6) : .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(feature.isComingSoon ? 0.8 : 1)
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
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    PurchaseView()
} 
