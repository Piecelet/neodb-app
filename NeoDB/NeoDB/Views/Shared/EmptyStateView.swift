//
//  EmptyStateView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String?
    let systemImage: String?
    let description: Text?
    let actions: AnyView

    init(
        _ title: String? = nil, systemImage: String? = nil,
        description: Text? = nil,
        @ViewBuilder actions: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.actions = AnyView(actions())
    }

    var body: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ContentUnavailableView(
                label: {
                    if let title = title,
                        let systemImage = systemImage
                    {
                        Label(title, systemImage: systemImage)
                    } else if let title = title {
                        Text(title)
                    } else if let systemImage = systemImage {
                        Image(systemName: systemImage)
                    } else {
                        EmptyView()
                    }
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
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                }

                Text(title ?? "")
                    .font(.title2)
                    .fontWeight(.bold)

                if let description = description {
                    description
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                actions
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}
