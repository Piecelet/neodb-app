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
        @available(iOS, deprecated: 17.0, message: "Use SensoryFeedback instead")
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
    
    /// Trigger impact feedback
    static func impact(_ level: ImpactLevel = .medium) {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            // On iOS 17+, we use UIKit feedback generators since we're not in a SwiftUI view context
            let generator = UIImpactFeedbackGenerator(style: level.uiKitStyle)
            generator.prepare()
            generator.impactOccurred()
        } else {
            let generator = UIImpactFeedbackGenerator(style: level.uiKitStyle)
            generator.prepare()
            generator.impactOccurred()
        }
        #endif
    }
    
    /// Trigger selection feedback
    static func selection() {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            // On iOS 17+, we use UIKit feedback generators since we're not in a SwiftUI view context
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        } else {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
        #endif
    }
    
    /// Trigger success feedback
    static func success() {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            // On iOS 17+, we use UIKit feedback generators since we're not in a SwiftUI view context
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
        #endif
    }
    
    /// Trigger error feedback
    static func error() {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            // On iOS 17+, we use UIKit feedback generators since we're not in a SwiftUI view context
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        }
        #endif
    }
    
    /// Trigger warning feedback
    static func warning() {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            // On iOS 17+, we use UIKit feedback generators since we're not in a SwiftUI view context
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        }
        #endif
    }
} 