//
//  SettingsViewHome.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/12/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import Defaults

struct SettingsViewHome: View {
    @Default(.defaultTab) private var defaultTab
    
    var body: some View {
        Section {
            HStack(spacing: 12) {
                Button {
                    defaultTab = .timelines
                    HapticFeedback.selection()
                } label: {
                    VStack(spacing: 8) {
                        Image("settings.customize.defaultHome.timelines")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(defaultTab == .timelines ? Color.accentColor : .clear, lineWidth: 2)
                            )
                        
                        HStack {
                            Text("Timelines")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if defaultTab == .timelines {
                                Image(systemSymbol: .checkmark)
                                    .foregroundColor(.accentColor)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                
                Button {
                    defaultTab = .discover
                    HapticFeedback.selection()
                } label: {
                    VStack(spacing: 8) {
                        Image("settings.customize.defaultHome.discover")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(defaultTab == .discover ? Color.accentColor : .clear, lineWidth: 2)
                            )
                        
                        HStack {
                            Text("Discover")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if defaultTab == .discover {
                                Image(systemSymbol: .checkmark)
                                    .foregroundColor(.accentColor)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        } header: {
            Text("Default Home Screen")
        } footer: {
            Text("Choose which screen to show when you open the app")
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    List {
        SettingsViewHome()
    }
}

