//
//  NeoDBApp.swift
//  NeoDB
//
//  Created by citron on 12/14/24.
//

import RevenueCat
import SwiftUI
import WhatsNewKit

@main
struct NeoDBApp: App {
    @StateObject private var accountsManager = AppAccountsManager()
    @StateObject private var storeManager = StoreManager()  // 全局唯一的 StoreManager
    @StateObject private var router = Router()

    var body: some Scene {
        WindowGroup {
            Group {
                if accountsManager.isAuthenticated {
                    ContentView()
                        .environmentObject(router)
                        .environment(
                            \.whatsNew,
                            WhatsNewEnvironment(
                                versionStore:
                                    UserDefaultsWhatsNewVersionStore(),
                                whatsNewCollection: self
                            )
                        )
                } else {
                    LoginView()
                }
            }
            .environmentObject(accountsManager)
            .environmentObject(storeManager)
            .onOpenURL { url in
                if url.scheme == "neodb" && url.host == "oauth" {
                    Task {
                        do {
                            try await accountsManager.handleCallback(
                                url: url,
                                ignoreAuthenticationDuration: true
                            )
                        } catch {
                            print("Authentication error: \(error)")
                        }
                    }
                    return
                }
                if !router.handleURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            // 使用 Swift 并发在全局监听 RevenueCat 的 customerInfoStream，随时更新用户订阅状态
            .task {
                for await customerInfo in Purchases.shared.customerInfoStream {
                    storeManager.customerInfo = customerInfo
                    storeManager.appUserID = Purchases.shared.appUserID
                }
            }
            .enableInjection()
        }
    }
    
    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
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
                cancellable = NotificationCenter.default.publisher(
                    for:
                        Notification.Name("INJECTION_BUNDLE_NOTIFICATION")
                )
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
            public func onInjection(bumpState: @escaping () -> Void)
                -> some SwiftUI.View
            {
                return
                    self
                    .onReceive(
                        InjectionObserver.shared.publisher, perform: bumpState
                    )
                    .eraseToAnyView()
            }
        }

        @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
        @propertyWrapper
        public struct ObserveInjection: DynamicProperty {
            @ObservedObject private var iO = InjectionObserver.shared
            public init() {}
            public private(set) var wrappedValue: Int {
                get { 0 }
                set {}
            }
        }
    #else
        extension SwiftUI.View {
            @inline(__always)
            public func eraseToAnyView() -> some SwiftUI.View { return self }
            @inline(__always)
            public func enableInjection() -> some SwiftUI.View { return self }
            @inline(__always)
            public func onInjection(bumpState: @escaping () -> Void)
                -> some SwiftUI.View
            {
                return self
            }
        }

        @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
        @propertyWrapper
        public struct ObserveInjection {
            public init() {}
            public private(set) var wrappedValue: Int {
                get { 0 }
                set {}
            }
        }
    #endif
#endif
