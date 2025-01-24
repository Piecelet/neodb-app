//
//  ContentMargins.swift
//  NeoDB
//
//  Created by citron on 1/25/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func safeContentMargins(
        _ length: CGFloat,
        for placement: Any = "automatic"
    ) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            self.contentMargins(length, for: placement as? ContentMarginPlacement ?? .automatic)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func safeContentMargins(
        _ edges: Edge.Set = .all,
        _ insets: EdgeInsets,
        for placement: Any = "automatic"
    ) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            self.contentMargins(edges, insets, for: placement as? ContentMarginPlacement ?? .automatic)
        } else {
            self
        }
    }
}
