//
//  SettingsViewHome.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/12/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Defaults
import SwiftUI

struct SettingsViewCustomizeHome: View {
    @Default(.defaultTab) private var defaultTab
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var router: Router

    var body: some View {
        Section {
            HStack(spacing: 12) {
                Button {
                    if defaultTab != .timelines {
                        if storeManager.isPlus {
                            defaultTab = .timelines
                            HapticFeedback.selection()
                            TelemetryService.shared.trackSettingsCustomizeDefaultTab(to: .timelines)
                        } else {
                            router.presentSheet(
                                .purchaseWithFeature(feature: .customize)
                            )
                            HapticFeedback.error()
                        }
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image("settings.customize.defaultHome.timelines")
                            .resizable()
                            .aspectRatio(1 / 1, contentMode: .fill)
                            .frame(width: 140, height: 120)
                            .offset(y: 15)
                            .overlay(alignment: .bottom) {
                                ZStack(alignment: .bottom) {
                                    LinearGradient(
                                        colors: [
                                            .clear, .black.opacity(0.1),
                                            .black.opacity(0.45),
                                            .black.opacity(0.6),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )

                                    Text("customize_home_timelines_label", tableName: "Settings")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(height: 80)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        defaultTab == .timelines
                                            ? Color.accentColor : .clear,
                                        lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        HStack {
                            if defaultTab == .timelines {
                                Circle()
                                    .fill(.accent)
                                    .frame(width: 24, height: 24)
                                    .overlay {
                                        Image(systemSymbol: .checkmark)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                            } else {
                                if storeManager.isPlus {
                                    Circle()
                                        .strokeBorder(
                                            .secondary.opacity(0.3),
                                            lineWidth: 1.5
                                        )
                                        .frame(width: 24, height: 24)
                                } else {
                                    Circle()
                                        .fill(.secondary.opacity(0.1))
                                        .frame(width: 24, height: 24)
                                        .overlay {
                                            Image(systemSymbol: .lock)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                Button {
                    if defaultTab != .discover {
                        if storeManager.isPlus {
                            defaultTab = .discover
                            HapticFeedback.selection()
                            TelemetryService.shared.trackSettingsCustomizeDefaultTab(to: .discover)
                        } else {
                            router.presentSheet(
                                .purchaseWithFeature(feature: .customize)
                            )
                            HapticFeedback.error()
                        }
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image("settings.customize.defaultHome.discover")
                            .resizable()
                            .aspectRatio(1 / 1, contentMode: .fill)
                            .frame(width: 140, height: 120)
                            .offset(y: 15)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(alignment: .bottom) {
                                ZStack(alignment: .bottom) {
                                    LinearGradient(
                                        colors: [
                                            .clear, .black.opacity(0.1),
                                            .black.opacity(0.45),
                                            .black.opacity(0.6),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )

                                    Text("customize_home_discover_label", tableName: "Settings")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(height: 80)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        defaultTab == .discover
                                            ? Color.accentColor : .clear,
                                        lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        HStack {
                            if defaultTab == .discover {
                                Circle()
                                    .fill(.accent)
                                    .frame(width: 24, height: 24)
                                    .overlay {
                                        Image(systemSymbol: .checkmark)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                            } else {
                                if storeManager.isPlus {
                                    Circle()
                                        .strokeBorder(
                                            .secondary.opacity(0.3),
                                            lineWidth: 1.5
                                        )
                                        .frame(width: 24, height: 24)
                                } else {
                                    Circle()
                                        .fill(.secondary.opacity(0.1))
                                        .frame(width: 24, height: 24)
                                        .overlay {
                                            Image(systemSymbol: .lock)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
            .listRowInsets(
                EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        } header: {
            Text("customize_home_title", tableName: "Settings")
        } footer: {
            Text("customize_home_description", tableName: "Settings")
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    List {
        SettingsViewCustomizeHome()
    }
}
