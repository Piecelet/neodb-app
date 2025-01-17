//
//  NeoDBApp.swift
//  NeoDB
//
//  Created by citron on 12/14/24.
//

import SwiftUI

@main
struct NeoDBApp: App {
    @StateObject private var accountsManager = AppAccountsManager()
    @StateObject private var router = Router()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if accountsManager.isAuthenticated {
                    ContentView()
                        .environmentObject(router)
                } else {
                    LoginView()
                }
            }
            .environmentObject(accountsManager)
            .onOpenURL { url in
                // First try to handle OAuth callback
                if url.scheme == "neodb" && url.host == "oauth" {
                    Task {
                        do {
                            try await accountsManager.handleCallback(url: url, ignoreAuthenticationDuration: true)
                        } catch {
                            print("Authentication error: \(error)")
                        }
                    }
                    return
                }
                
                // Then try to handle deep links
                if !router.handleURL(url) {
                    // If the router didn't handle the URL, open it in the default browser
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}

#if canImport(HotSwiftUI)
@_exported import HotSwiftUI
#elseif canImport(Inject)
@_exported import Inject
#else
// This code can be found in the Swift package:
// https://github.com/johnno1962/HotSwiftUI or
// https://github.com/krzysztofzablocki/Inject

#if DEBUG
import Combine

public class InjectionObserver: ObservableObject {
    public static let shared = InjectionObserver()
    @Published var injectionNumber = 0
    var cancellable: AnyCancellable? = nil
    let publisher = PassthroughSubject<Void, Never>()
    init() {
        cancellable = NotificationCenter.default.publisher(for:
            Notification.Name("INJECTION_BUNDLE_NOTIFICATION"))
            .sink { [weak self] change in
            self?.injectionNumber += 1
            self?.publisher.send()
        }
    }
}

extension SwiftUI.View {
    public func eraseToAnyView() -> some SwiftUI.View {
        return AnyView(self)
    }
    public func enableInjection() -> some SwiftUI.View {
        return eraseToAnyView()
    }
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
            .onReceive(InjectionObserver.shared.publisher, perform: bumpState)
            .eraseToAnyView()
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct ObserveInjection: DynamicProperty {
    @ObservedObject private var iO = InjectionObserver.shared
    public init() {}
    public private(set) var wrappedValue: Int {
        get {0} set {}
    }
}
#else
extension SwiftUI.View {
    @inline(__always)
    public func eraseToAnyView() -> some SwiftUI.View { return self }
    @inline(__always)
    public func enableInjection() -> some SwiftUI.View { return self }
    @inline(__always)
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct ObserveInjection {
    public init() {}
    public private(set) var wrappedValue: Int {
        get {0} set {}
    }
}
#endif
#endif
