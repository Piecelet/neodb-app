//
//  StarRatingView.swift
//  NeoDB
//
//  Created by citron on 1/25/25.
//

import SwiftUI
import UIKit

// Assuming HapticFeedback struct is declared externally

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
    @State private var rating: Double = 0
    private let starSize: CGFloat = 40
    private let starSpacing: CGFloat = 10
    private let starCount = 5

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
    }

    private func starImageName(forIndex index: Int) -> String {
        if rating >= Double(index + 1) {
            return "star.fill"
        } else if rating > Double(index) && rating < Double(index + 1) {
            return "star.leadinghalf.fill" // Still using leadinghalf.fill for logic, but visually hidden by overlay
        } else {
            return "star" // Visually hidden by overlay
        }
    }

    // Calculate fill amount for each star based on rating
    private func starFillAmount(forIndex index: Int) -> CGFloat {
        let starValue = Double(index + 1)
        if rating >= starValue {
            return 1.0 // Full fill
        } else if rating > starValue - 1 && rating < starValue {
            return CGFloat(rating - Double(index)) // Partial fill (for half-star)
        } else {
            return 0.0 // No fill
        }
    }


    private func performFeedback(forRatingChange oldRating: Double) {
        if rating > oldRating { // Rating increased
            if rating == floor(rating) {
                HapticFeedback.impact(.medium)
            } else {
                HapticFeedback.impact(.light)
            }
        } else if rating < oldRating { // Rating decreased
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


        let oldRating = rating
        rating = newRating
        print("Current Rating: \(rating)")
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


        let oldRating = rating
        if validRating != rating {
            rating = validRating
            print("Current Rating (Drag): \(rating)")
            performFeedback(forRatingChange: oldRating)
        }
    }

    private func clearRating() {
        let oldRating = rating
        rating = 0
        print("Rating cleared")
        if oldRating > 0 {
            HapticFeedback.selection()
        }
    }
}

struct StarRatingView_Previews: PreviewProvider {
    static var previews: some View {
        StarRatingView()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
