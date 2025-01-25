//
//  StarRatingView.swift
//  NeoDB
//
//  Created by citron on 1/25/25.
//

import CoreHaptics
import OSLog
import SwiftUI

// MARK: - Custom Clip Shape for Dynamic Width Rectangle
struct StarClipShape: Shape {
    var fillAmount: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(
            CGRect(
                x: rect.minX, y: rect.minY, width: rect.width * fillAmount,
                height: rect.height))
        return path
    }
}

struct StarRatingView: View {
    @Binding var inputRating: Int?  // Binding to allow external control
    @State private var internalRating: Double = 0  // Internal rating state for display and interaction
    @State private var engine: CHHapticEngine?
    @State private var starWidth: CGFloat = 0
    @State private var firstStarMaxX: CGFloat = 0
    @State private var secondStarMinX: CGFloat = 0
    private let logger = Logger.views.mark.starRating
    private let starSize: CGFloat = 36
    private let starSpacing: CGFloat = 14
    private let starCount = 5

    // Initialize internalRating based on inputRating
    init(inputRating: Binding<Int?>) {
        _inputRating = inputRating
        _internalRating = State(
            initialValue: StarRatingView.ratingValue(
                for: inputRating.wrappedValue))
    }

    private static func ratingValue(for input: Int?) -> Double {
        guard let input = input else { return 0 }
        if input <= 0 { return 0 }  // Handle 0 and negative input as 0 stars
        return Double(input) / 2.0  // Convert 0-10 scale to 0-5 scale
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                HStack(spacing: starSpacing) {
                    ForEach(0..<starCount, id: \.self) { index in
                        // 1. Base Star (Unselected state)
                        Image(systemName: "star.fill")
                            .font(.system(size: starSize))
                            .frame(width: starSize, height: starSize)
                            .foregroundColor(.secondary.opacity(0.2))  // Secondary color for unselected
                            .overlay {
                                // 2. Overlay Star (Selected state)
                                Image(systemName: "star.fill")
                                    .font(.system(size: starSize))
                                    .foregroundColor(.orange.opacity(0.8))
                                    .clipShape(
                                        StarClipShape(
                                            fillAmount: starFillAmount(
                                                forIndex: index))
                                    )
                                    .animation(
                                        .spring(duration: 0.3),
                                        value: internalRating)
                            }
                            .onTapGesture { location in
                                withAnimation(.spring(duration: 0.3)) {
                                    handleStarTap(
                                        location: location,
                                        index: index)
                                }
                            }
                            .background(
                                GeometryReader { proxy in
                                    Color.clear
                                        .task(id: proxy.size) {
                                            if starWidth != proxy.size.width {
                                                starWidth = proxy.size.width
                                                logger.debug(
                                                    "Star width updated: \(starWidth)"
                                                )
                                            }
                                            let frame = proxy.frame(in: .global)
                                            if index == 0 {
                                                firstStarMaxX = frame.maxX
                                            } else if index == 1 {
                                                secondStarMinX = frame.minX
                                            }
                                        }
                                }
                            )
                    }
                }
                .frame(width: geometry.size.width, alignment: .center)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.spring(duration: 0.3)) {
                                handleDragChanged(
                                    value: value,
                                    geometry: geometry)
                            }
                        }
                )
            }
            .frame(height: starSize)
            .frame(maxWidth: .infinity, alignment: .center)

            Group {
                if internalRating > 0 {
                    Button("Clear", systemSymbol: .xmark) {
                        withAnimation(.spring(duration: 0.3)) {
                            clearRating()
                        }
                    }
                    .labelStyle(.titleAndIcon)
                    .buttonStyle(.plain)
                } else {
                    Text("Tap to review")
                }
            }
            .foregroundStyle(.secondary)
            .padding(.top)
            .font(.footnote)
            .animation(.spring(duration: 0.3), value: internalRating)
        }
        .padding(.top)
        .frame(maxWidth: .infinity)
        .onChange(of: inputRating) { newValue in  // Observe inputRating changes
            internalRating = StarRatingView.ratingValue(for: newValue)  // Update internalRating when inputRating changes
        }
        .onAppear(perform: prepareHaptics)
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private func starImageName(forIndex index: Int) -> String {
        if internalRating >= Double(index + 1) {
            return "star.fill"
        } else if internalRating > Double(index)
            && internalRating < Double(index + 1)
        {
            return "star.leadinghalf.fill"  // Still using leadinghalf.fill for logic, but visually hidden by overlay
        } else {
            return "star"  // Visually hidden by overlay
        }
    }

    // Calculate fill amount for each star based on rating
    private func starFillAmount(forIndex index: Int) -> CGFloat {
        let starValue = Double(index + 1)
        if internalRating >= starValue {
            return 1.0  // Full fill
        } else if internalRating > starValue - 1 && internalRating < starValue {
            return CGFloat(internalRating - Double(index))  // Partial fill (for half-star)
        } else {
            return 0.0  // No fill
        }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            logger.error(
                "Failed to start haptic engine: \(error.localizedDescription)")
        }
    }

    private func performFeedback(forRatingChange oldRating: Double) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
            let engine = engine
        else {
            fallbackHaptics(forRating: internalRating)
            return
        }

        do {
            let intensity = getHapticIntensity(for: internalRating)
            let sharpness = getHapticSharpness(for: internalRating)

            let intensityParameter = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: Float(intensity))
            let sharpnessParameter = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: Float(sharpness))

            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensityParameter, sharpnessParameter],
                relativeTime: 0)

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            logger.error(
                "Failed to play haptics: \(error.localizedDescription)")
            fallbackHaptics(forRating: internalRating)
        }
    }

    private func getHapticIntensity(for rating: Double) -> Double {
        let baseIntensity = rating / 5.0  // 0.2 到 1.0
        let isHalfStar = rating != floor(rating)

        // 调整基础强度，使其更符合评分感觉
        let adjustedIntensity =
            switch ceil(rating) {
            case 1.0: 0.4  // 最低评分也要有明显感觉
            case 2.0: 0.55
            case 3.0: 0.7
            case 4.0: 0.85
            case 5.0: 0.95  // 稍微降低最高评分的强度
            default: baseIntensity
            }

        // 半星降低 20% 强度
        return isHalfStar ? adjustedIntensity * 0.8 : adjustedIntensity
    }

    private func getHapticSharpness(for rating: Double) -> Double {
        let baseSharpness = rating / 5.0  // 0.2 到 1.0
        let isHalfStar = rating != floor(rating)

        // 调整锐度，使触感更加清晰
        let adjustedSharpness =
            switch ceil(rating) {
            case 1.0: 0.3  // 柔和但清晰
            case 2.0: 0.4
            case 3.0: 0.5
            case 4.0: 0.6
            case 5.0: 0.7  // 保持适中的锐度
            default: baseSharpness
            }

        // 半星略微增加锐度以区分
        return isHalfStar ? adjustedSharpness * 1.2 : adjustedSharpness
    }

    private func fallbackHaptics(forRating rating: Double) {
        // 当 CoreHaptics 不可用时的后备方案
        let isHalfStar = rating != floor(rating)
        let intensity: Double = isHalfStar ? 0.5 : 1.0

        let level: HapticFeedback.ImpactLevel =
            switch ceil(rating) {
            case 1.0: .light
            case 2.0: .light
            case 3.0: .medium
            case 4.0: .medium
            case 5.0: .heavy
            default: .medium
            }

        HapticFeedback.impact(level, intensity: intensity)
    }

    private func handleStarTap(
        location: CGPoint,
        index: Int
    ) {
        let starIndex = Double(index)
        let tapPositionInStar = location.x
        let ratingIncrement = tapPositionInStar <= starWidth / 2 ? 0.5 : 1.0
        var newRating = starIndex + ratingIncrement

        logger.debug(
            """
            Tap Debug:
            - Location: \(location)
            - Star Width: \(starWidth)
            - Star Index: \(starIndex)
            - Tap Position: \(tapPositionInStar)
            - Rating Increment: \(ratingIncrement)
            - New Rating: \(newRating)
            """)

        // Enforce minimum rating of 0.5
        if newRating < 0.5 && newRating > 0 {
            newRating = 0.5
            logger.debug("Adjusted to minimum rating: 0.5")
        } else if newRating <= 0 {
            newRating = 0.5
            logger.debug("Adjusted zero/negative to: 0.5")
        }

        let oldRating = internalRating
        internalRating = newRating
        inputRating = Int(round(internalRating * 2))
        logger.debug(
            "Rating changed: \(oldRating) -> \(newRating) (input: \(inputRating ?? 0))"
        )
        performFeedback(forRatingChange: oldRating)
    }

    private func handleDragChanged(
        value: DragGesture.Value, geometry: GeometryProxy
    ) {
        withAnimation(.spring(duration: 0.3)) {
            let dragLocation = value.location
            let singleSpacing = secondStarMinX - firstStarMaxX
            let starAreaWidth =
                (starWidth * CGFloat(starCount))
                + (singleSpacing * CGFloat(starCount - 1))
            let screenWidth = geometry.size.width
            let padding = (screenWidth - starAreaWidth) / 2

            // 计算实际评分
            func calculateRating(x: CGFloat, spacingCount: Int = 0) -> Double {
                let adjustedX =
                    x - padding - (singleSpacing * CGFloat(spacingCount))
                let rating = adjustedX / starWidth

                logger.debug("""
                    
                    Drag Debug \(spacingCount):
                    - X: \(x - padding)
                    - Adjusted X: \(adjustedX)
                    - Rating: \(rating)
                    - Spacing Count: \(spacingCount)
                    - nextRating: \(rating - 1 - CGFloat(spacingCount))
                    """)

                if spacingCount >= starCount {
                    return rating
                }

                if (rating - 1 - CGFloat(spacingCount)) >= 0 {
                    // 如果当前评分大于等于0，继续尝试下一个间距
                    let nextRating = calculateRating(
                        x: x, spacingCount: spacingCount + 1)
                    // 如果下一个间距的评分小于0，说明当前是正确的间距
                    if (nextRating - 1 - CGFloat(spacingCount)) < 0 {
                        return rating
                    }
                    return nextRating
                }
                return rating
            }

            let rawRating = calculateRating(x: dragLocation.x)
            let snappedRating =
                (rawRating * 2).rounded(.toNearestOrAwayFromZero) / 2
            var validRating = min(max(0, snappedRating), Double(starCount))

//            logger.debug(
//                """
//                Drag Debug:
//                - Location: \(dragLocation)
//                - Single Spacing: \(singleSpacing)
//                - Star Width: \(starWidth)
//                - Star Area Width: \(starAreaWidth)
//                - Geometry Size: \(geometry.size.width)
//                - Padding: \(padding)
//                - Raw Rating: \(rawRating)
//                - Snapped Rating: \(snappedRating): \(rawRating * 2) \((rawRating * 2).rounded(.toNearestOrAwayFromZero) / 2)
//                - Valid Rating: \(validRating)
//                """)

            // Enforce minimum rating of 0.5
            if validRating < 0.5 && validRating > 0 {
                validRating = 0.5
            } else if validRating <= 0 {
                validRating = 0.5
            }

            let oldRating = internalRating
            if validRating != internalRating {
                internalRating = validRating
                inputRating = Int(round(internalRating * 2))
                logger.debug(
                    "Rating changed: \(oldRating) -> \(validRating) (input: \(inputRating ?? 0))"
                )
                performFeedback(forRatingChange: oldRating)
            }
        }
    }

    private func clearRating() {
        let oldRating = internalRating
        internalRating = 0
        inputRating = 0  // Clear inputRating as well
        logger.debug("Rating cleared")
        if oldRating > 0 {
            HapticFeedback.selection()
        }
    }
}

struct StarRatingView_Previews: PreviewProvider {
    static var previews: some View {
        // Example with initial rating set to 3 (1.5 stars)
        StarRatingView(inputRating: .constant(3))
            .previewLayout(.sizeThatFits)
            .padding()

        // Example with no initial rating (nil)
        StarRatingView(inputRating: .constant(nil))
            .previewLayout(.sizeThatFits)
            .padding()

        // Example with zero initial rating
        StarRatingView(inputRating: .constant(0))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
