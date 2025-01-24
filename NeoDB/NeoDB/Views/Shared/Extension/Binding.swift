//
//  Binding.swift
//  NeoDB
//
//  Created by citron on 2/24/25.
//

import SwiftUI

extension Binding {
    func onUpdate(_ closure: @escaping (Value, Value) -> Void) -> Binding<Value> {
        Binding(get: {
            wrappedValue
        }, set: { newValue in
            let oldValue = wrappedValue
            wrappedValue = newValue
            closure(oldValue, newValue)
        })
    }
} 