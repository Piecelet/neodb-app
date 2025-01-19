//
//  AppStorage.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation
import SwiftUI

struct AppStorageKeys {
    init() { }
    
    var customInstance: AppStorageKey<String> { .init("custom_instance", defaultValue: "") }
    var timelinesPosition: AppStorageKey<Int> { .init("timelines_position", defaultValue: 0) }
    var mark: Mark { .init() }
    
    struct Mark {
        var postToFediverse: AppStorageKey<Bool> { .init("mark_post_to_fediverse", defaultValue: false) }
        var isPublic: AppStorageKey<Bool> { .init("mark_is_public", defaultValue: true) }
    }
}

struct AppStorageKey<Value> {
    let name: String
    let defaultValue: Value
    
    init(_ name: String, defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

extension AppStorage where Value == String {
    init(wrappedValue: String, strongKey: AppStorageKey<Value>, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, strongKey.name, store: store)
    }
    
    init(wrappedValue: Value,
         strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>,
         store: UserDefaults? = nil) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]
        self.init(wrappedValue: wrappedValue, strongKey: strongKey, store: store)
    }
    
    init(wrappedValue: Value,
         _ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        self.init(wrappedValue: wrappedValue, strongKeyPath: strongKeyPath, store: nil)
    }
    
    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>, store: UserDefaults? = nil) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]
        self.init(wrappedValue: strongKey.defaultValue, strongKey: strongKey, store: store)
    }
    
    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        self.init(strongKeyPath, store: nil)
    }
}

extension AppStorage where Value == Bool {
    init(wrappedValue: Value,
         _ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]
        self.init(wrappedValue: wrappedValue, strongKey.name)
    }
}

extension AppStorage where Value == Int {
    init(wrappedValue: Value,
         _ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]
        self.init(wrappedValue: wrappedValue, strongKey.name)
    }
    
    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]
        self.init(wrappedValue: strongKey.defaultValue, strongKey.name)
    }
}

