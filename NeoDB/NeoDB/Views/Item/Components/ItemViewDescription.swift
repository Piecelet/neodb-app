//
//  ItemViewDescription.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/4/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import ExpandableText

struct ItemViewDescription: View {
    let item: (any ItemProtocol)?
    
    private var description: String { item?.description ?? "" }
    
    var body: some View {
        if !description.isEmpty {
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
    }
}

