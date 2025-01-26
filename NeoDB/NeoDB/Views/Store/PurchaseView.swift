//
//  PurchaseView.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

@MainActor
class PurchaseViewModel: NSObject, ObservableObject {
    @Published private(set) var purchaseError: String?
    @Published var isLoading = false
    @Published var showAllPlans = false
    @Published var selectedPackage: Package?
    @Published var shouldDismiss = false

    private let storeManager: StoreManager

    init(storeManager: StoreManager) {
        self.storeManager = storeManager
        super.init()
        Task {
            await loadOfferings()
        }
    }

    var customerInfo: CustomerInfo? {
        storeManager.customerInfo
    }

    var currentOffering: Offering? {
        storeManager.plusOffering
    }

    func loadOfferings() async {
        isLoading = true
        await storeManager.loadOfferings()

        selectedPackage = currentOffering?.availablePackages.first {
            $0.packageType == .annual
        }
        isLoading = false
    }

    func purchase(_ package: Package) async {
        isLoading = true

        do {
            let customerInfo = try await storeManager.purchase(package)
            if !customerInfo.entitlements.active.isEmpty {
                shouldDismiss = true
            }
        } catch {
            purchaseError = error.localizedDescription
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true

        do {
            let customerInfo = try await storeManager.restorePurchases()
            if !customerInfo.entitlements.active.isEmpty {
                shouldDismiss = true
            }
        } catch {
            purchaseError = error.localizedDescription
        }

        isLoading = false
    }
}

struct PurchaseView: View {
    @StateObject private var viewModel: PurchaseViewModel
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    init() {
        _viewModel = StateObject(
            wrappedValue: PurchaseViewModel(storeManager: StoreManager()))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Piecelet+")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(
                        "Unlock a richer experience for your NeoDB journey"
                    )
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
        .navigationTitle("Piecelet+")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Piecelet+")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    .hidden()
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
        .safeAreaInset(edge: .bottom) {
            BottomPurchaseView(
                offering: viewModel.currentOffering,
                showAllPlans: $viewModel.showAllPlans,
                selectedPackage: $viewModel.selectedPackage,
                viewModel: viewModel
            )
            .background(.bar)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -4)
        }
        .enableInjection()
        .toolbar(.hidden, for: .tabBar)
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
                        .foregroundStyle(
                            feature.isComingSoon
                                ? Color.primary.opacity(0.8) : .primary)

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
                    .foregroundStyle(
                        feature.isComingSoon
                            ? Color.secondary.opacity(0.6) : .secondary)
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
    let viewModel: PurchaseViewModel

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
            } else {
                // Plans Selector
                if let offering = offering {
                    VStack {
                        Button {
                            withAnimation {
                                showAllPlans.toggle()
                            }
                        } label: {
                            HStack {
                                Text(
                                    showAllPlans
                                        ? "Hide all plans" : "Show all plans"
                                )
                                .font(.headline)
                                Image(
                                    systemName: showAllPlans
                                        ? "chevron.down" : "chevron.up")
                            }
                        }
                        .foregroundStyle(Color.primary)

                        if showAllPlans {
                            VStack(spacing: 8) {
                                ForEach(
                                    offering.availablePackages.sorted {
                                        $0.storeProduct.price
                                            < $1.storeProduct.price
                                    }, id: \.identifier
                                ) { package in
                                    Button {
                                        selectedPackage = package
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(
                                                    package.packageType
                                                        == .lifetime
                                                        ? "Lifetime • \(package.storeProduct.localizedPriceString)"
                                                        : "\(package.packageType == .annual ? "Yearly" : "Monthly") • \(package.storeProduct.localizedPriceString)"
                                                )
                                                .font(.headline)
                                            }

                                            Spacer()

                                            if package.packageType == .annual {
                                                Text("SAVE 44%")
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        Color.accentColor
                                                    )
                                                    .foregroundStyle(.white)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .padding()
                                    .background(
                                        selectedPackage?.identifier
                                            == package.identifier
                                            ? .gray.opacity(0.2) : .clear
                                    )
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 12))
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
                                    await viewModel.purchase(selectedPackage)
                                }
                            } label: {
                                Text("Try Free For 7 Days")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)

                            if selectedPackage.packageType == .annual {
                                Text(
                                    "Then \(selectedPackage.storeProduct.localizedPriceString) per year • Cancel anytime"
                                )
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical)
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
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
                        Text(
                            package.packageType == .annual
                                ? "per year" : "per month"
                        )
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
