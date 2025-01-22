//
//  LocalizationText.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import SwiftUI

enum StringTable: String {
    case navigation = "Navigation"
    case mainScreen = "MainScreen"
    case settings = "Settings"
    case library = "Library"
    case search = "Search"
    case item = "Item"
}

extension Text {
    init(_ key: String, table: StringTable) {
        self.init(LocalizedStringKey(key), tableName: table.rawValue)
    }
}

extension String {
    init(_ key: String, stringTable: StringTable) {
        self.init(localized: LocalizationValue(key), table: stringTable.rawValue)
    }
}

