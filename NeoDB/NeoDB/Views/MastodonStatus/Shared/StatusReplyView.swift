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
            Text("timelines_status_reply_development", tableName: "Timelines")

            Button(action: {
                router.presentSheet(.purchase)
            }) {
                Text("store_plus_purchase_to_get_faster_development", tableName: "Settings")
            }
            .buttonStyle(.borderedProminent)
            .padding()
            Spacer()
        }
        .background(.ultraThinMaterial)
        .presentationDetents([.fraction(0.25)])
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
