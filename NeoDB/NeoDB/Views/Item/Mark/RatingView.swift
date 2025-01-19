//
//  RatingView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI

struct RatingView: View {
    @Binding var rating: Int?
    let maxStars: Int

    private var floatRating: Binding<Float> {
        Binding(
            get: { Float(rating ?? 0) / 2 },
            set: { newValue in
                rating = Int(round(newValue * 2))
            }
        )
    }

    init(rating: Binding<Int?>, maxStars: Int = 5) {
        self._rating = rating
        self.maxStars = maxStars
    }

    var body: some View {
        HStack {
            StarRatingView(rating: floatRating, color: .yellow)
                .frame(height: 30)

            if rating != nil {
                Button {
                    rating = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

private struct StarRatingView: View {
    @Binding private var rating: Float
    private let color: Color
    private let maxRating: Float

    init(rating: Binding<Float>, color: Color = .yellow, maxRating: Float = 5) {
        self._rating = rating
        self.color = color
        self.maxRating = maxRating
    }

    var body: some View {
        GeometryReader { geometry in
            let starHeight = floor(geometry.size.height)
            let spacing = floor(starHeight * 0.2)
            let totalWidth = (starHeight + spacing) * CGFloat(maxRating)

            HStack(spacing: spacing) {
                ForEach(0..<fullStars, id: \.self) { _ in
                    fullStar
                        .frame(width: starHeight, height: starHeight)
                }
                if hasHalfStar {
                    halfStar
                        .frame(width: starHeight, height: starHeight)
                }
                ForEach(0..<emptyStars, id: \.self) { _ in
                    emptyStar
                        .frame(width: starHeight, height: starHeight)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateRating(
                            at: value.location.x, totalWidth: totalWidth)
                    }
            )
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private var fullStars: Int {
        Int(rating)
    }

    private var hasHalfStar: Bool {
        (rating - Float(fullStars)) >= 0.5
    }

    private var emptyStars: Int {
        Int(maxRating) - fullStars - (hasHalfStar ? 1 : 0)
    }

    private var fullStar: some View {
        Image(systemName: "star.fill")
            .resizable()
            .foregroundColor(color)
    }

    private var halfStar: some View {
        Image(systemName: "star.leadinghalf.filled")
            .resizable()
            .foregroundColor(color)
    }

    private var emptyStar: some View {
        Image(systemName: "star")
            .resizable()
            .foregroundColor(color)
    }

    private func updateRating(at x: CGFloat, totalWidth: CGFloat) {
        let position = max(0, min(x, totalWidth))
        let newRating = Float(position / totalWidth * CGFloat(maxRating))
        rating = round(newRating * 2) / 2  // Round to nearest 0.5
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var rating: Int? = 7

        var body: some View {
            RatingView(rating: $rating)
                .padding()
                .enableInjection()
        }

        #if DEBUG
            @ObserveInjection var forceRedraw
        #endif
    }

    return PreviewWrapper()
}
