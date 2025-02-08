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
    @StateObject private var router = Router()

    var body: some View {
        MainTabView()
            .environmentObject(router)
            .enableInjection()
            .whatsNewSheet()
            .tint(.accentColor)
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
