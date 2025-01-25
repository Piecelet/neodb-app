//
//  StarRatingView.swift
//  NeoDB
//
//  Created by citron on 1/25/25.
//

import SwiftUI
import OSLog


// MARK: - Custom Clip Shape for Dynamic Width Rectangle
struct StarClipShape: Shape {
    var fillAmount: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width * fillAmount, height: rect.height))
        return path
    }
}

struct StarRatingView: View {
    @Binding var inputRating: Int? // Binding to allow external control
    @State private var internalRating: Double = 0 // Internal rating state for display and interaction
    private let logger = Logger.views.mark.starRating
    private let starSize: CGFloat = 40
    private let starSpacing: CGFloat = 10
    private let starCount = 5

    // Initialize internalRating based on inputRating
    init(inputRating: Binding<Int?>) {
        _inputRating = inputRating
        _internalRating = State(initialValue: StarRatingView.ratingValue(for: inputRating.wrappedValue))
    }

    private static func ratingValue(for input: Int?) -> Double {
        guard let input = input else { return 0 }
        if input <= 0 { return 0 } // Handle 0 and negative input as 0 stars
        return Double(input) / 2.0 // Convert 0-10 scale to 0-5 scale
    }


    var body: some View {
        VStack {
            Text("Mufasa: The Lion King")
                .padding(.bottom, 8)

            GeometryReader { geometry in
                HStack(spacing: starSpacing) {
                    ForEach(0..<starCount) { index in
                        ZStack(alignment: .leading) { // Use ZStack for overlay
                            // 1. Base Star (Unselected state)
                            Image(systemName: "star.fill")
                                .font(.system(size: starSize))
                                .foregroundColor(.secondary) // Secondary color for unselected

                            // 2. Overlay Star (Selected state)
                            Image(systemName: "star.fill")
                                .font(.system(size: starSize))
                                .foregroundColor(.orange) // Orange color for selected
                                .clipShape( // Use clipShape with custom Shape
                                    StarClipShape(fillAmount: starFillAmount(forIndex: index))
                                )
                        }
                        .onTapGesture { location in
                            handleStarTap(location: location, index: index, geometry: geometry)
                        }
                    }
                }
                .frame(width: geometry.size.width, alignment: .center)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            handleDragChanged(value: value, geometry: geometry)
                        }
                )
            }
            .frame(height: starSize)
            .frame(maxWidth: .infinity, alignment: .center)

            Button("Clear") {
                clearRating()
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .onChange(of: inputRating) { newValue in // Observe inputRating changes
            internalRating = StarRatingView.ratingValue(for: newValue) // Update internalRating when inputRating changes
        }
    }

    private func starImageName(forIndex index: Int) -> String {
        if internalRating >= Double(index + 1) {
            return "star.fill"
        } else if internalRating > Double(index) && internalRating < Double(index + 1) {
            return "star.leadinghalf.fill" // Still using leadinghalf.fill for logic, but visually hidden by overlay
        } else {
            return "star" // Visually hidden by overlay
        }
    }

    // Calculate fill amount for each star based on rating
    private func starFillAmount(forIndex index: Int) -> CGFloat {
        let starValue = Double(index + 1)
        if internalRating >= starValue {
            return 1.0 // Full fill
        } else if internalRating > starValue - 1 && internalRating < starValue {
            return CGFloat(internalRating - Double(index)) // Partial fill (for half-star)
        } else {
            return 0.0 // No fill
        }
    }


    private func performFeedback(forRatingChange oldRating: Double) {
        if internalRating > oldRating { // Rating increased
            if internalRating == floor(internalRating) {
                HapticFeedback.impact(.medium)
            } else {
                HapticFeedback.impact(.light)
            }
        } else if internalRating < oldRating { // Rating decreased
            HapticFeedback.selection()
        }
    }

    private func handleStarTap(location: CGPoint, index: Int, geometry: GeometryProxy) {
        let totalSpacing = CGFloat(starCount - 1) * starSpacing
        let starAreaWidth = geometry.size.width - totalSpacing
        let starWidth = starAreaWidth / CGFloat(starCount)

        let starIndex = Double(index)
        let tapPositionInStar = location.x
        let ratingIncrement = tapPositionInStar <= starWidth / 2 ? 0.5 : 1.0
        var newRating = starIndex + ratingIncrement

        // Enforce minimum rating of 0.5
        if newRating < 0.5 && newRating > 0 {
            newRating = 0.5
        } else if newRating <= 0 {
            newRating = 0.5 // If tap is before the first star, set to 0.5
        }


        let oldRating = internalRating
        internalRating = newRating
        inputRating = Int(round(internalRating * 2)) // Update inputRating based on internal rating change
        print("Current Rating: \(internalRating)")
        performFeedback(forRatingChange: oldRating)
    }

    private func handleDragChanged(value: DragGesture.Value, geometry: GeometryProxy) {
        let dragLocation = value.location
        let totalSpacing = CGFloat(starCount - 1) * starSpacing
        let starAreaWidth = geometry.size.width - totalSpacing
        let starWidth = starAreaWidth / CGFloat(starCount)

        let rawRating = dragLocation.x / starWidth
        var snappedRating = (rawRating * 2).rounded(.toNearestOrAwayFromZero) / 2
        var validRating = min(max(0, snappedRating), Double(starCount)) // Ensure rating is within 0 to starCount

        // Enforce minimum rating of 0.5
        if validRating < 0.5 && validRating > 0 {
            validRating = 0.5
        } else if validRating <= 0 {
            validRating = 0.5 // If drag is before the first star, set to 0.5
        }


        let oldRating = internalRating
        if validRating != internalRating {
            internalRating = validRating
            inputRating = Int(round(internalRating * 2)) // Update inputRating based on internal rating change
            logger.debug("Current Rating (Drag): \(internalRating)")
            performFeedback(forRatingChange: oldRating)
        }
    }

    private func clearRating() {
        let oldRating = internalRating
        internalRating = 0
        inputRating = 0 // Clear inputRating as well
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
