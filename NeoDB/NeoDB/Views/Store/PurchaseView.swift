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
    @Published var isLoading = true
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

    func calculateSavings(for annualPackage: Package, in offering: Offering)
        -> Int?
    {
        guard
            let monthlyPackage = offering.availablePackages.first(where: {
                $0.packageType == .monthly
            })
        else {
            return nil
        }

        let monthlyPrice = monthlyPackage.storeProduct.price as Decimal
        let annualPrice = annualPackage.storeProduct.price as Decimal
        let twelve = Decimal(12)
        let hundred = Decimal(100)
        let monthlyTotal = monthlyPrice * twelve
        var savings = (monthlyTotal - annualPrice) / monthlyTotal * hundred
        var rounded = Decimal()
        NSDecimalRound(&rounded, &savings, 0, .plain)

        return Int(truncating: rounded as NSNumber)
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
        defer { isLoading = false }

        do {
            let customerInfo = try await storeManager.purchase(package)
            if !customerInfo.entitlements.active.isEmpty {
                shouldDismiss = true
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {

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

enum PurchaseViewType {
    case view
    case sheet
}

struct PurchaseView: View {
    @StateObject private var viewModel: PurchaseViewModel
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var type: PurchaseViewType = .view

    init(type: PurchaseViewType = .view) {
        self._viewModel = StateObject(
            wrappedValue: PurchaseViewModel(storeManager: StoreManager()))
        self.type = type
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    VStack(spacing: 0) {
                        Image("piecelet-symbol")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)

                        Text(String(localized: "store_title", table: "Settings"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.leading, 8)
                    }

                    Text(String(localized: "store_description", table: "Settings"))
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

                HStack(spacing: 16) {
                    Button(String(localized: "store_terms", table: "Settings")) {
                        openURL(StoreConfig.URLs.termsOfService)
                    }
                    Button(String(localized: "store_privacy", table: "Settings")) {
                        openURL(StoreConfig.URLs.privacyPolicy)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(.top, type == .view ? 0 : 32)
            .padding(.bottom, 32)
        }
        .navigationTitle(String(localized: "store_title", table: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(String(localized: "store_title", table: "Settings"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    .hidden()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "store_button_restore", table: "Settings")) {
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
            Image(symbol: feature.icon)
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
                        Text("store_badge_soon", tableName: "Settings")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    if feature.isFree {
                        Text("store_badge_free", tableName: "Settings")
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
    private enum PackageText {
        case lifetime(price: String)
        case yearly(price: String)
        case monthly(price: String)
        case purchased(package: Package)

        var buttonText: String {
            switch self {
            case .lifetime:
                return String(localized: "store_button_upgrade_forever", table: "Settings")
            case .yearly:
                return String(localized: "store_button_try_free", table: "Settings")
            case .monthly:
                return String(localized: "store_button_upgrade_now", table: "Settings")
            case .purchased:
                return String(localized: "store_button_thank_you", table: "Settings")
            }
        }

        var descriptionText: String {
            switch self {
            case .lifetime(let price):
                return String(format: String(localized: "store_package_lifetime_price", table: "Settings"), price)
            case .yearly(let price):
                return String(format: String(localized: "store_package_yearly_price", table: "Settings"), price)
            case .monthly(let price):
                return String(format: String(localized: "store_package_monthly_price", table: "Settings"), price)
            case .purchased(let package):
                switch package.packageType {
                case .lifetime:
                    return String(localized: "store_package_lifetime", table: "Settings")
                case .annual:
                    return String(localized: "store_package_annual", table: "Settings")
                case .monthly:
                    return String(localized: "store_package_monthly", table: "Settings")
                default:
                    return String(localized: "store_package_active", table: "Settings")
                }
            }
        }
    }

    let offering: Offering?
    @Binding var showAllPlans: Bool
    @Binding var selectedPackage: Package?
    @EnvironmentObject private var storeManager: StoreManager
    let viewModel: PurchaseViewModel

    private func getPackageText(for package: Package) -> PackageText {
        if storeManager.isPlus {
            return .purchased(package: package)
        }

        let price = package.storeProduct.localizedPriceString
        switch package.packageType {
        case .lifetime:
            return .lifetime(price: price)
        case .annual:
            return .yearly(price: price)
        case .monthly:
            return .monthly(price: price)
        default:
            return .monthly(price: price)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
            } else {
                // Plans Selector
                if let offering = offering {
                    if !storeManager.isPlus {
                        VStack {
                            Button {
                                withAnimation {
                                    showAllPlans.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(
                                        showAllPlans
                                            ? String(localized: "store_plans_hide", table: "Settings")
                                            : String(localized: "store_plans_show", table: "Settings")
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
                                                        (package.packageType
                                                            == .lifetime
                                                            ? String(localized: "store_package_lifetime", table: "Settings")
                                                            : "\(package.packageType == .annual ? String(localized: "store_package_yearly", table: "Settings") : String(localized: "store_package_monthly_short", table: "Settings"))") + " • \(package.storeProduct.localizedPriceString)"
                                                    ).font(.headline)
                                                    
                                                }

                                                Spacer()

                                                if package.packageType
                                                    == .annual
                                                {
                                                    if let savings =
                                                        viewModel
                                                        .calculateSavings(
                                                            for: package,
                                                            in: offering)
                                                    {
                                                        Text(String(format: String(localized: "store_badge_save", table: "Settings"), String(savings)))
                                                            .font(.caption)
                                                            .padding(
                                                                .horizontal, 8
                                                            )
                                                            .padding(
                                                                .vertical, 4
                                                            )
                                                            .background(
                                                                Color
                                                                    .accentColor
                                                            )
                                                            .foregroundStyle(
                                                                .white
                                                            )
                                                            .clipShape(
                                                                Capsule())
                                                    }
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    }

                    // Action Button
                    if let selectedPackage = selectedPackage {
                        let packageText = getPackageText(for: selectedPackage)
                        VStack(spacing: 4) {
                            Button {
                                Task {
                                    await viewModel.purchase(selectedPackage)
                                }
                            } label: {
                                Text(packageText.buttonText)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        storeManager.isPlus
                                            ? Color.gray : Color.accentColor
                                    )
                                    .foregroundStyle(.white)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(storeManager.isPlus)
                            .padding(.horizontal)

                            Text(packageText.descriptionText)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
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
                        Text(String(localized: "store_purchase_onetime", table: "Settings"))
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
                                ? String(format: String(localized: "store_period_year", table: "Settings"), package.storeProduct.localizedPriceString)
                                : String(format: String(localized: "store_period_month", table: "Settings"), package.storeProduct.localizedPriceString)
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
