//
//  Symbol.swift
//  NeoDB
//
//  Created by citron on 1/20/25.
//

import Foundation
import SFSafeSymbols

enum Symbol {
    case sfSymbol(SFSymbol)
    case systemSymbol(String)
    case custom(String)
}
