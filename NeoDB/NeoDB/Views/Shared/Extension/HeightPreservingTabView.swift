//
//  HeightPreservingTabView.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import SwiftUI

/// A variant of `TabView` that sets an appropriate `minHeight` on its frame.
struct HeightPreservingTabView<SelectionValue: Hashable, Content: View>: View {
  var selection: Binding<SelectionValue>?
  @ViewBuilder var content: () -> Content

  // `minHeight` needs to start as something non-zero or we won't measure the interior content height
  @State private var minHeight: CGFloat = 1

  var body: some View {
    TabView(selection: selection) {
      content()
        .background {
          GeometryReader { geometry in
            Color.clear.preference(
              key: TabViewMinHeightPreference.self,
              value: geometry.frame(in: .local).height
            )
          }
        }
    }
    .frame(minHeight: minHeight)
    .onPreferenceChange(TabViewMinHeightPreference.self) { minHeight in
      self.minHeight = minHeight
    }
  }
}

private struct TabViewMinHeightPreference: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    // It took me so long to debug this line
    value = max(value, nextValue())
  }
}
