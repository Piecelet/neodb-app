//
//  MastodonTimelinesUnreadStatusesObserver.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Perception
import SwiftUI

@MainActor
@Perceptible
class MastodonTimelinesUnreadStatusesObserver {
    var pendingStatusesCount: Int = 0

    var disableUpdate: Bool = false

    var isLoadingNewStatuses: Bool = false

    var pendingStatuses: [String] = [] {
        didSet {
            withAnimation(.default) {
                pendingStatusesCount = pendingStatuses.count
            }
        }
    }

    func removeStatus(status: MastodonStatus) {
        if !disableUpdate, let index = pendingStatuses.firstIndex(of: status.id)
        {
            pendingStatuses.removeSubrange(index...(pendingStatuses.count - 1))
        }
    }

    init() {}
}

struct MastodonTimelinesUnreadStatusesView: View {

    @State var observer: MastodonTimelinesUnreadStatusesObserver
    let onButtonTap: (String?) -> Void

    var body: some View {
        if observer.pendingStatusesCount > 0 || observer.isLoadingNewStatuses {
            Button {
                onButtonTap(observer.pendingStatuses.last)
            } label: {
                HStack(spacing: 8) {
                    if observer.isLoadingNewStatuses {
                        ProgressView()
                    }
                    if observer.pendingStatusesCount > 0 {
                        if #available(iOS 17.0, *) {
                            Text("\(observer.pendingStatusesCount)")
                                .contentTransition(
                                    .numericText(
                                        value: Double(observer.pendingStatusesCount)
                                    )
                                )
                            // Accessibility: this results in a frame with a size of at least 44x44 at regular font size
                                .frame(minWidth: 16, minHeight: 16)
                                .font(.footnote.monospacedDigit())
                                .fontWeight(.bold)
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
            }
            .accessibilityLabel(
                "accessibility.tabs.timeline.unread-posts.label-\(observer.pendingStatusesCount)"
            )
            .cornerRadius(8)
            .padding(8)
            .frame(
                maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
