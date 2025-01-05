//
//  NeoDBApp.swift
//  NeoDB
//
//  Created by citron on 12/14/24.
//

import SwiftUI

@main
struct NeoDBApp: App {
    @StateObject private var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .onOpenURL { url in
                Task {
                    do {
                        try await authService.handleCallback(url: url)
                    } catch {
                        print("Authentication error: \(error)")
                    }
                }
            }
        }
    }
}
