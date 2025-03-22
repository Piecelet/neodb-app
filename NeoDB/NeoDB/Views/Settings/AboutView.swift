//
//  AboutView.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    var body: some View {
        List {
            // App Info Section
            Section {
                HStack(spacing: 16) {
                    Image("piecelet-symbol")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Piecelet")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(appVersion) (\(buildNumber))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.vertical)
            }
            
            // Actions Section
            Section {
                Button {
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(AppConfig.appStoreId)?action=write-review") {
                        openURL(url)
                    }
                } label: {
                    Label(String(localized: "about_rate_us", table: "Settings"), systemImage: "star")
                }
                
                Button {
                    shareApp()
                } label: {
                    Label(String(localized: "about_share", table: "Settings"), systemImage: "square.and.arrow.up")
                }
            }
            
            // Social Media Section
            Section {
                Link(destination: URL(string: "https://mastodon.social/@piecelet")!) {
                    HStack {
                        Label(String(localized: "about_social_mastodon", table: "Settings"), systemImage: "link")
                        Spacer()
                        Text("@piecelet")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://m.cmx.im/@piecelet")!) {
                    HStack {
                        Label(String(localized: "about_social_mastodon_cn", table: "Settings"), systemImage: "link")
                        Spacer()
                        Text("@piecelet")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://bsky.app/profile/neodb.app")!) {
                    HStack {
                        Label(String(localized: "about_social_bluesky", table: "Settings"), systemImage: "link")
                        Spacer()
                        Text("neodb.app")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(String(localized: "about_social_title", table: "Settings"))
            }
            
            // Links Section
            Section {
                Link(destination: URL(string: "https://blog.citrons.cc")!) {
                    HStack {
                        Label(String(localized: "about_developer_blog", table: "Settings"), systemImage: "link")
                        Spacer()
                        Text("citrons.cc")
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://twitter.com/vanillaCitron")!) {
                    HStack {
                        Label(String(localized: "about_developer_twitter", table: "Settings"), systemImage: "link")
                        Spacer()
                        Text("@vanillaCitron")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://github.com/lcandy2")!) {
                    HStack {
                        Label(String(localized: "about_developer_github", table: "Settings"), systemImage: "link")
                        Spacer()
                        Text("@lcandy2")
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://lcandy.bsky.app")!) {
                    HStack {
                        Label(String(localized: "about_developer_bluesky", table: "Settings"), systemImage: "link")
                        Spacer()
                        Text("@lcandy.bsky.app")
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://mastodon.social/@seril")!) {
                    HStack {
                        Label(String(localized: "about_developer_mastodon", table: "Settings"), systemImage: "link")
                        Spacer()
                        Text("@seril")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(String(localized: "about_developer_links_title", table: "Settings"))
            }

            // Policy Section
            Section {
                Link(destination: URL(string: "https://github.com/lcandy2/neodb-app")!) {
                    HStack {
                        Label(String(localized: "about_policy_github", table: "Settings"), systemImage: "link")
                        Spacer()
                        Text("@lcandy2/neodb-app")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Link(destination: StoreConfig.URLs.privacyPolicy) {
                    HStack {
                        Label(String(localized: "policy_privacy_policy", table: "Settings"), systemImage: "link")
                        Spacer()
                        Text("piecelet.app/privacy")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Link(destination: StoreConfig.URLs.termsOfService) {
                    HStack {
                        Label(String(localized: "policy_terms_of_use", table: "Settings"), systemImage: "link")
                        Spacer()
                        Text("piecelet.app/terms")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(String(localized: "about_policy_title", table: "Settings"))
            }
            
            // Telemetry Section
            Section {
                Toggle(isOn: Binding(
                    get: { TelemetryService.shared.isEnabled() },
                    set: { TelemetryService.shared.setTelemetryEnabled($0) }
                )) {
                    Label(String(localized: "about_telemetry_toggle", defaultValue: "Usage Data & Improvements", table: "Settings"), systemImage: "chart.bar")
                }
            } header: {
                Text(String(localized: "about_telemetry_title", defaultValue: "User Experience", table: "Settings"))
            } footer: {
                Text(String(localized: "about_telemetry_footer", defaultValue: "Send anonymized data to TelemetryDeck to help improve the app.", table: "Settings"))
            }
        }
        .navigationTitle(String(localized: "about_title", table: "Settings"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func shareApp() {
        let text = String(localized: "about_share_text", table: "Settings")
        let url = URL(string: "https://apps.apple.com/app/id6476473920")!
        
        #if os(iOS)
        let activityVC = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}

