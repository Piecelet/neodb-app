import SwiftUI

#if os(iOS)
    import UIKit
#endif

/// A wrapper for providing haptic feedback across different iOS versions and platforms
@MainActor
enum HapticFeedback {
    /// Standard impact feedback levels
    enum ImpactLevel {
        case light
        case medium
        case heavy
        case rigid
        case soft

        #if os(iOS)
            var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
                switch self {
                case .light: return .light
                case .medium: return .medium
                case .heavy: return .heavy
                case .rigid: return .rigid
                case .soft: return .soft
                }
            }
        #endif
    }

    // 缓存 Impact Generators
    private static var impactGenerators: [ImpactLevel: UIImpactFeedbackGenerator] = [:]

    /// Trigger impact feedback
    static func impact(_ level: ImpactLevel = .medium) {
        #if os(iOS)
            let generator: UIImpactFeedbackGenerator
            if let cachedGenerator = impactGenerators[level] {
                generator = cachedGenerator // 复用缓存的 generator
            } else {
                generator = UIImpactFeedbackGenerator(style: level.uiKitStyle)
                impactGenerators[level] = generator // 缓存新的 generator
            }
            // generator.prepare() // 可以选择性保留 prepare()，但通常复用情况下 prepare 的意义不大
            generator.impactOccurred()
        #endif
    }

    // 缓存 Selection Generator
    private static var selectionGenerator: UISelectionFeedbackGenerator?

    /// Trigger selection feedback
    static func selection() {
        #if os(iOS)
            let generator: UISelectionFeedbackGenerator
            if let cachedGenerator = selectionGenerator {
                generator = cachedGenerator // 复用缓存的 generator
            } else {
                generator = UISelectionFeedbackGenerator()
                selectionGenerator = generator // 缓存新的 generator
            }
            // generator.prepare() // 可以选择性保留 prepare()，但通常复用情况下 prepare 的意义不大
            generator.selectionChanged()
        #endif
    }

    // 缓存 Notification Generator
    private static var notificationGenerator: UINotificationFeedbackGenerator?

    /// Trigger success feedback
    static func success() {
        notificationFeedback(.success)
    }

    /// Trigger error feedback
    static func error() {
        notificationFeedback(.error)
    }

    /// Trigger warning feedback
    static func warning() {
        notificationFeedback(.warning)
    }

    private static func notificationFeedback(_ notificationType: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
            let generator: UINotificationFeedbackGenerator
            if let cachedGenerator = notificationGenerator {
                generator = cachedGenerator // 复用缓存的 generator
            } else {
                generator = UINotificationFeedbackGenerator()
                notificationGenerator = generator // 缓存新的 generator
            }
            // generator.prepare() // 可以选择性保留 prepare()，但通常复用情况下 prepare 的意义不大
            generator.notificationOccurred(notificationType)
        #endif
    }
}
