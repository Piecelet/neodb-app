//
//  Image.swift
//  NeoDB
//
//  Created by citron on 1/20/25.
//

import SwiftUI
import SFSafeSymbols

extension Image {
    init(symbol: Symbol) {
        switch symbol {
        case .sfSymbol(let symbol):
            self.init(systemSymbol: symbol)
        case .systemSymbol(let name):
            self.init(systemName: name)
        case .custom(let name):
            self.init(name)
        }
    }
}
