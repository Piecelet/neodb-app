//
//  ItemViewDescription.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/4/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import ExpandableText
import SwiftUI

struct ItemViewDescription: View {
    let item: (any ItemProtocol)?

    private var description: String { item?.description ?? "" }

    private var trackList: String {
        if let item = item as? AlbumSchema {
            return item.trackList ?? ""
        }
        return ""
    }

    var body: some View {
        Group {
            if !description.isEmpty {
                Divider()
                    .padding(.vertical)

                VStack(alignment: .leading, spacing: 8) {
                    Text("item_description", tableName: "Item")
                        .font(.headline)

                    ExpandableText(description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }

            if !trackList.isEmpty {
                Divider()
                    .padding(.vertical)

                VStack(alignment: .leading, spacing: 8) {
                    Text("metadata_album_track_list_label", tableName: "Item")
                        .font(.headline)

                    ExpandableText(trackList)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
        }
    }
}
