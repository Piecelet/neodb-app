//
//  ContentView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 12/14/24.
//

import OSLog
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var accountsManager: AppAccountsManager
    @EnvironmentObject var storeManager: StoreManager

    var body: some View {
        MainTabView()
            .tint(.accentColor)
            .enableInjection()
            .whatsNewSheet()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    ContentView()
        .environmentObject(AppAccountsManager())
        .environmentObject(StoreManager())
}
