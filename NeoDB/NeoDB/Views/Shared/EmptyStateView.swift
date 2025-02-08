//
//  EmptyStateView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: Text
    let actions: AnyView
    
    init(_ title: String, systemImage: String, description: Text, @ViewBuilder actions: () -> some View = { EmptyView() }) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.actions = AnyView(actions())
    }
    
    var body: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ContentUnavailableView(
                label: {
                    Label(title, systemImage: systemImage)
                },
                description: {
                    description
                },
                actions: {
                    actions
                }
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                description
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                actions
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
} 
