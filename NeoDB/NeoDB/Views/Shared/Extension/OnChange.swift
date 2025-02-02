//
//  OnChange.swift
//  NeoDB
//
//  Created by citron on 1/24/25.
//

import SwiftUI
import Combine

// MARK: - 新版扩展（使用不同名称避免冲突）
extension View {
    /// 兼容新旧系统的带旧值监听的修饰符
    /// 命名为 onChangeWithPrevious 避免与系统 API 冲突
    @ViewBuilder
    func onChangeWithPrevious<V: Equatable>(
        of value: V,
        initial: Bool = false,
        _ action: @escaping (_ previous: V, _ current: V) -> Void
    ) -> some View {
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            // iOS 17+ 原生实现适配
            self.modifier(NativeChangeWithPreviousModifier(value: value, initial: initial, action: action))
        } else {
            // iOS 16- 自定义实现
            self.modifier(LegacyChangeWithPreviousModifier(value: value, initial: initial, action: action))
        }
    }
}

// MARK: - iOS 17+ 原生实现
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
private struct NativeChangeWithPreviousModifier<V: Equatable>: ViewModifier {
    let value: V
    let initial: Bool
    let action: (V, V) -> Void
    
    @State private var storedValue: V
    
    init(value: V, initial: Bool, action: @escaping (V, V) -> Void) {
        self.value = value
        self.initial = initial
        self.action = action
        self._storedValue = State(initialValue: value)
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: value, initial: initial) { old, new in
                action(old, new)
                storedValue = new
            }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

// MARK: - iOS 16- 自定义实现
private struct LegacyChangeWithPreviousModifier<V: Equatable>: ViewModifier {
    let value: V
    let initial: Bool
    let action: (V, V) -> Void
    
    @State private var storedValue: V
    @State private var hasInitialized = false
    
    init(value: V, initial: Bool, action: @escaping (V, V) -> Void) {
        self.value = value
        self.initial = initial
        self.action = action
        self._storedValue = State(initialValue: value)
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if initial && !hasInitialized {
                    action(storedValue, storedValue)
                    hasInitialized = true
                }
            }
            .onReceive(Just(value)) { newValue in
                if newValue != storedValue {
                    action(storedValue, newValue)
                    storedValue = newValue
                }
                
                if initial && !hasInitialized {
                    action(storedValue, newValue)
                    hasInitialized = true
                }
            }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}
