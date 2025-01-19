//
//  OverlayAdapter.swift
//  
//
//  Created by ned on 25/02/23.
//

import SwiftUI

internal struct OverlayAdapter<V: View>: ViewModifier {
    let alignment: Alignment
    let view: () -> V
    
    init(alignment: Alignment, @ViewBuilder view: @escaping () -> V) {
        self.alignment = alignment
        self.view = view
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.overlay(alignment: alignment, content: view)
        } else {
            content.overlay(view(), alignment: alignment)
        }
    }
}
