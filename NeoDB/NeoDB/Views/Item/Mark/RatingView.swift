//
//  RatingView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI

struct RatingView: View {
    @Binding var rating: Int?
    let maxStars: Int = 5
    
    private var floatRating: Binding<Float> {
        Binding(
            get: { Float(rating ?? 0) / 2 },
            set: { rating = Int(round($0 * 2)) }
        )
    }
    
    var body: some View {
        HStack {
            StarRatingView(rating: floatRating, maxRating: Float(maxStars))
                .frame(height: 30)
                .animation(.easeInOut, value: rating)
            
            if rating != nil {
                clearButton
            }
        }
        .enableInjection()
    }
    
    private var clearButton: some View {
        Button {
            withAnimation {
                rating = nil
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.leading, 8)
        .accessibilityLabel("Clear rating")
    }
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
            let starSize = geometry.size.height
            let totalWidth = (starSize + spacing(starSize)) * CGFloat(maxRating)
            
            HStack(spacing: spacing(starSize)) {
                ForEach(0..<Int(maxRating), id: \.self) { index in
                    starView(for: index)
                        .frame(width: starSize, height: starSize)
                        .accessibilityLabel(label(for: index))
                        .accessibilityRemoveTraits(.isImage)
                }
            }
            .frame(width: totalWidth, alignment: .leading)
            .contentShape(Rectangle())
            .gesture(dragGesture(totalWidth: totalWidth))
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
    
    // MARK: - Private Helpers
    
    private func spacing(_ starSize: CGFloat) -> CGFloat {
        starSize * 0.2
    }
    
    private func starView(for index: Int) -> some View {
        Group {
            if Float(index) < rating.roundedDown {
                fullStar
            } else if needsHalfStar(index) {
                halfStar
            } else {
                emptyStar
            }
        }
    }
    
    private func label(for index: Int) -> String {
        let value = rating - Float(index)
        if value >= 1 {
            return "Full star"
        } else if value >= 0.5 {
            return "Half star"
        }
        return "Empty star"
    }
    
    private var fullStar: some View {
        starImage("star.fill")
    }
    
    private var halfStar: some View {
        starImage("star.leadinghalf.filled")
    }
    
    private var emptyStar: some View {
        starImage("star")
    }
    
    private func starImage(_ name: String) -> some View {
        Image(systemName: name)
            .resizable()
            .foregroundColor(color)
    }
    
    private func needsHalfStar(_ index: Int) -> Bool {
        rating > Float(index) && rating < Float(index + 1)
    }
    
    private func dragGesture(totalWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let newRating = calculateRating(
                    x: value.location.x,
                    totalWidth: totalWidth
                )
                rating = min(max(newRating, 0), maxRating)
            }
    }
    
    private func calculateRating(x: CGFloat, totalWidth: CGFloat) -> Float {
        let percentage = max(0, min(x / totalWidth, 1))
        return (Float(percentage) * maxRating).roundedToNearestHalf()
    }
}

// MARK: - Float Extension

private extension Float {
    var roundedDown: Float {
        Darwin.floor(self)
    }
    
    func roundedToNearestHalf() -> Float {
        (self * 2).rounded() / 2
    }
}
