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
                    HStack {
                        Label("Home", systemSymbol: .house)
                        Spacer()
                        if defaultTab == .timelines {
                            Image(systemSymbol: .checkmark)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                    defaultTab = .discover
                    HapticFeedback.selection()
                } label: {
                    HStack {
                        Label("Search", systemSymbol: .magnifyingglass)
                        Spacer()
                        if defaultTab == .discover {
                            Image(systemSymbol: .checkmark)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.grayBackground)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        } header: {
            Text("Main Interface")
        } footer: {
            Text("Choose which tab to show when you open the app")
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

