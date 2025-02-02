//
//  EdgeInsets.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/2/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

extension EdgeInsets {
    static func horizontal(_ value: CGFloat, vertical: CGFloat = 10) -> EdgeInsets {
        EdgeInsets(top: vertical, leading: value, bottom: vertical, trailing: value)
    }
    
    static func vertical(_ value: CGFloat, horizontal: CGFloat = 10) -> EdgeInsets {
        EdgeInsets(top: value, leading: horizontal, bottom: value, trailing: horizontal)
    }
}

