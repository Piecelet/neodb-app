//
//  ListSectionSpacing.swift
//  NeoDB
//
//  Created by citron on 1/25/25.
//

import SwiftUI

extension View {
    func safeListSectionSpacing(_ value: CGFloat) -> some View {
        self.modifier(SafeListSectionSpacing(value: value))
    }
}

private struct SafeListSectionSpacing: ViewModifier {
    
    var value: CGFloat
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .listSectionSpacing(value)
        } else {
            content
        }
    }
}
