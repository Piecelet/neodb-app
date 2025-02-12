//
//  HapticService.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/8/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import CoreHaptics
import UIKit

@MainActor
class HapticService {
    static let shared: HapticService = .init()

    #if os(visionOS)
        enum FeedbackType: Int {
            case success, warning, error
        }
    #endif

    enum HapticType {
        case buttonPress
        case dataRefresh(intensity: CGFloat)
        #if os(visionOS)
            case notification(_ type: FeedbackType)
        #else
            case notification(
                _ type: UINotificationFeedbackGenerator.FeedbackType)
        #endif
        case tabSelection
        case timeline
    }

    enum ImpactLevel {
        case light
        case medium
        case heavy
        case rigid
        case soft
    }

    #if !os(visionOS)
        private let selectionGenerator = UISelectionFeedbackGenerator()
        private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
        private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
        private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        private let rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
        private let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
        private let notificationGenerator = UINotificationFeedbackGenerator()
    #endif

    private init() {
        #if !os(visionOS)
            selectionGenerator.prepare()
            lightImpactGenerator.prepare()
            mediumImpactGenerator.prepare()
            heavyImpactGenerator.prepare()
            rigidImpactGenerator.prepare()
            softImpactGenerator.prepare()
            notificationGenerator.prepare()
        #endif
    }

    /// Trigger impact feedback
    @MainActor
    func impact(_ level: ImpactLevel = .medium, intensity: Double = 1.0) {
        #if os(iOS)
            switch level {
            case .light:
                lightImpactGenerator.impactOccurred(intensity: intensity)
            case .medium:
                mediumImpactGenerator.impactOccurred(intensity: intensity)
            case .heavy:
                heavyImpactGenerator.impactOccurred(intensity: intensity)
            case .rigid:
                rigidImpactGenerator.impactOccurred(intensity: intensity)
            case .soft:
                softImpactGenerator.impactOccurred(intensity: intensity)
            }
        #endif
    }

    @MainActor
    func selection() {
        #if !os(visionOS)
            selectionGenerator.selectionChanged()
        #endif
    }

    @MainActor
    func success() {
        #if !os(visionOS)
            notificationGenerator.notificationOccurred(.success)
        #endif
    }

    @MainActor
    func error() {
        #if !os(visionOS)
            notificationGenerator.notificationOccurred(.error)
        #endif
    }

    @MainActor
    func warning() {
        #if !os(visionOS)
            notificationGenerator.notificationOccurred(.warning)
        #endif
    }

    @MainActor
    func fireHaptic(_ type: HapticType) {
        #if !os(visionOS)
            guard supportsHaptics else { return }

            switch type {
            case .buttonPress:
                heavyImpactGenerator.impactOccurred()
            case let .dataRefresh(intensity):
                heavyImpactGenerator.impactOccurred(intensity: intensity)
            case let .notification(type):
                notificationGenerator.notificationOccurred(type)
            case .tabSelection:
                selectionGenerator.selectionChanged()
            case .timeline:
                selectionGenerator.selectionChanged()
            }
        #endif
    }

    var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
}
