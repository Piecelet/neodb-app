//
//  StatusReplyView.swift
//  NeoDB
//
//  Created by citron on 2/20/25.
//

import SwiftUI
import OSLog

struct StatusReplyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var router: Router

    let status: MastodonStatus
    
    init(status: MastodonStatus) {
        self.status = status
    }
    
    var body: some View {
        VStack {
            // Custom title bar
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }
            }
            .padding()

            EmptyStateView(
                String(localized: "status_reply_in_development", table: "Timelines"),
                systemImage: "bubble.left.and.text.bubble.right",
                description: Text(String(localized: "store_plus_subscription_to_get_faster_development", table: "Settings")),
                actions: {
                    Button {
                        router.navigate(to: .purchase)
                    } label: {
                        Text("store_plus_subscription_button", tableName: "Settings")
                            .font(.body)
                    }
                }
            )
            .padding(.bottom, 30)
            
            Spacer()
        }
        .background(.ultraThinMaterial)
        .presentationDetents([.fraction(0.45)])
        .presentationDragIndicator(.visible)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    StatusReplyView(status: .placeholder())
        .environmentObject(AppAccountsManager())
} 
