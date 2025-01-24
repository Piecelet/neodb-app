//
//  Searchable.swift
//  NeoDB
//
//  Created by citron on 1/24/25.
//

import SwiftUI

extension View {
    public func searchable_iOS16(text: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey? = nil) -> some View {
        modifier(Searchable_iOS16(text: text, isPresented: isPresented, placement: placement, prompt: prompt))
    }
}

public struct Searchable_iOS16: ViewModifier {
    @Binding var text: String
    @Binding var isPresented: Bool
    @State var legacyIsSearching = false
    var placement: SearchFieldPlacement = .automatic
    var prompt: LocalizedStringKey? = nil

    public func body(content: Content) -> some View {
        #if os(watchOS) || os(tvOS)
            bodyLegacy(content)
        #else
            if #available(iOS 17, macOS 14, *) {
                bodyModern(content)
            } else {
                bodyLegacy(content)
            }
        #endif
    }

    @available(iOS 17, macOS 14, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func bodyModern(_ content: Content) -> some View {
        content
        .searchable(text: $text, isPresented: $isPresented, placement: placement)
    }

    public func bodyLegacy(_ content: Content) -> some View {
        SearchableInner_iOS16(legacyIsSearching: $legacyIsSearching) {
            content
        }
        .searchable(text: $text, placement: placement)
        .onChange(of: legacyIsSearching) { isPresented = $0 }
        .onAppear { isPresented = legacyIsSearching }
    }
}

struct SearchableInner_iOS16<Content: View>: View {
    @Environment(\.isSearching) private var environmentIsSearching
    @Binding var legacyIsSearching: Bool
    var content: () -> Content

    init(legacyIsSearching: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self._legacyIsSearching = legacyIsSearching
        self.content = content
    }
    
    var body: some View {
        content()
        .onChange(of: environmentIsSearching) { legacyIsSearching = $0 }
        .onAppear { legacyIsSearching = environmentIsSearching }
    }
}
