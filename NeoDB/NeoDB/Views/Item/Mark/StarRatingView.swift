//
//  StarRatingView.swift
//  NeoDB
//
//  Created by citron on 1/25/25.
//

import SwiftUI

struct StarRatingView: View {
    @State private var rating: Double = 0
    private let starSize: CGFloat = 30       // 统一的星星大小
    private let starSpacing: CGFloat = 8    // 统一的星星间距
    private let starCount = 5

    var body: some View {
        VStack {
            Text("Mufasa: The Lion King")
                .padding(.bottom, 8)

            GeometryReader { geometry in
                HStack(spacing: starSpacing) {
                    ForEach(0..<starCount) { index in
                        Image(systemName: starImageName(forIndex: index))
                            .font(.system(size: starSize)) // 使用统一的星星大小
                            .foregroundColor(.orange)
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
            .frame(height: starSize) // GeometryReader 高度与星星大小一致
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
            return "star.leadinghalf.fill"
        } else {
            return "star"
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
        let newRating = starIndex + ratingIncrement
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
        let snappedRating = (rawRating * 2).rounded(.toNearestOrAwayFromZero) / 2
        let validRating = min(max(0, snappedRating), Double(starCount)) // Ensure rating is within 0 to starCount
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
