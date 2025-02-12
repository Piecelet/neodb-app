//
//  WelcomeView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var router: Router

    // Animation states
    @State private var logoScale = 0.5
    @State private var contentOpacity = 0.0
    @State private var titleOffset = CGFloat(50)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                VStack(spacing: 16) {
                    Image("piecelet-symbol")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .scaleEffect(logoScale)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.6),
                            value: logoScale)

                    Text(String(localized: "welcome_title", table: "Settings"))
                        .font(.title)
                        .fontWeight(.bold)
                        .offset(y: titleOffset)
                        .opacity(contentOpacity)

                    Text(
                        String(
                            localized: "welcome_description", table: "Settings")
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(contentOpacity)
                }

                Spacer()

                NavigationLink {
                    InstanceView()
                } label: {
                    Text("welcome_get_started", tableName: "Settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    HapticFeedback.impact()
                })
                .opacity(contentOpacity)

                HStack(spacing: 16) {
                    
                    Text(String(localized: "welcome_present_by", table: "Settings"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(String(localized: "policy_terms_of_use", table: "Settings"))
                    {
                        openURL(StoreConfig.URLs.termsOfService)
                    }
                    Button(
                        String(localized: "policy_privacy_policy", table: "Settings")
                    ) {
                        openURL(StoreConfig.URLs.privacyPolicy)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .opacity(contentOpacity)
            }
            .padding()
        }
        .task {
            // Trigger animations
            withAnimation(.easeOut(duration: 0.6)) {
                logoScale = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                contentOpacity = 1.0
                titleOffset = 0
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
