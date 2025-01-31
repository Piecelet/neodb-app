//
//  PurchaseView.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import RevenueCat
import SwiftUI

enum PurchaseViewType {
    case view
    case sheet
}

struct PurchaseView: View {
    @EnvironmentObject private var storeManager: StoreManager
    @StateObject private var viewModel = PurchaseViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var type: PurchaseViewType = .view

    init(type: PurchaseViewType = .view) {
        self.type = type
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 头部 Logo 与描述
                VStack(spacing: 8) {
                    VStack(spacing: 0) {
                        Image("piecelet-symbol")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                        Text(
                            String(localized: "store_title", table: "Settings")
                        )
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading, 8)
                    }
                    Text(
                        String(
                            localized: "store_description", table: "Settings")
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
                
                HStack(spacing: 16) {
                    Button(String(localized: "store_terms", table: "Settings"))
                    {
                        openURL(StoreConfig.URLs.termsOfService)
                    }
                    Button(
                        String(localized: "store_privacy", table: "Settings")
                    ) {
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
                Button(
                    String(localized: "store_button_restore", table: "Settings")
                ) {
                    Task {
                        await viewModel.restorePurchases()
                    }
                }
            }
        }
        .task {
            await viewModel.initializeIfNeeded(with: storeManager)
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
        .toolbar(.hidden, for: .tabBar)
        .enableInjection()
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

#Preview {
    PurchaseView()
        .environmentObject(StoreManager())
}
