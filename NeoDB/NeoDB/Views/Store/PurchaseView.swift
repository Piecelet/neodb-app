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
    @Published var showAllPlans = false
    @Published var selectedPackage: Package?
    @Published var shouldDismiss = false
    
    override init() {
        super.init()
        Purchases.shared.delegate = self
        
        Task {
            await updateCustomerInfo()
        }
    }
    
    func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.offering(identifier: "plus") ?? offerings.current
            // 默认选择年度套餐
            selectedPackage = currentOffering?.availablePackages.first { $0.packageType == .annual }
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
            // Only set shouldDismiss if purchase is successful and user has active entitlements
            if result.customerInfo.entitlements.active.isEmpty == false {
                shouldDismiss = true
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }
    
    func restorePurchases() async {
//        isLoading = true
//        defer { isLoading = false }
//        
//        do {
//            let info = try await Purchases.shared.restorePurchases()
//            customerInfo = info
//            // Only set shouldDismiss if restore is successful and user has active entitlements
//            if info.entitlements.active.isEmpty == false {
//                shouldDismiss = true
//            }
//        } catch {
//            purchaseError = error.localizedDescription
//        }
    }
    
    private func updateCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            customerInfo = info
            // Don't auto-dismiss on initial customer info load
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
            // Don't auto-dismiss on delegate updates
        }
    }
}

struct PurchaseView: View {
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var showAllPlans = false
    @State private var selectedPackage: Package?
    
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
                }
                .padding(.vertical, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Restore") {
                        Task {
                            _ = await storeManager.getCurrentCustomerInfo()
                        }
                    }
                }
            }
            .task {
                
            }
            .safeAreaInset(edge: .bottom) {
                BottomPurchaseView(
                    offering: storeManager.plusOffering,
                    showAllPlans: $showAllPlans,
                    selectedPackage: $selectedPackage
                )
                .background(.bar)
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

struct BottomPurchaseView: View {
    let offering: Offering?
    @Binding var showAllPlans: Bool
    @Binding var selectedPackage: Package?
    @EnvironmentObject private var storeManager: StoreManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Plans Selector
            if let offering = offering {
                VStack {
                    Button {
                        withAnimation {
                            showAllPlans.toggle()
                        }
                    } label: {
                        HStack {
                            Text(showAllPlans ? "Hide all plans" : "Show all plans")
                                .font(.headline)
                            Image(systemName: showAllPlans ? "chevron.up" : "chevron.down")
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    if showAllPlans {
                        VStack(spacing: 8) {
                            ForEach(offering.availablePackages.sorted { $0.storeProduct.price < $1.storeProduct.price }, id: \.identifier) { package in
                                Button {
                                    selectedPackage = package
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(package.packageType == .lifetime ? "Lifetime • \(package.storeProduct.localizedPriceString)" : "\(package.packageType == .annual ? "Yearly" : "Monthly") • \(package.storeProduct.localizedPriceString)")
                                                .font(.headline)
                                        }
                                        
                                        Spacer()
                                        
                                        if package.packageType == .annual {
                                            Text("SAVE 44%")
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.accentColor)
                                                .foregroundStyle(.white)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding()
                                .background(selectedPackage?.identifier == package.identifier ? .gray.opacity(0.2) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding(.horizontal)
                
                // Action Button
                if let selectedPackage = selectedPackage {
                    VStack(spacing: 4) {
                        Button {
                            Task {
                                // TODO: Purchase
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
                        
                        if selectedPackage.packageType == .annual {
                            Text("Then \(selectedPackage.storeProduct.localizedPriceString) per year • Cancel anytime")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
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
        .environmentObject(StoreManager())
} 
