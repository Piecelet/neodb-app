//
//  StarRatingView.swift
//  NeoDB
//
//  Created by citron on 1/25/25.
//

import SwiftUI

struct StarRatingView: View {
    @State private var rating: Double = 0

    var body: some View {
        VStack {
            Text("Mufasa: The Lion King")
                .padding(.bottom, 8) // 增加标题和星星之间的间距

            GeometryReader { geometry in
                HStack(spacing: 10) { // 使用 spacing 设置星星之间的间距
                    ForEach(0..<5) { index in
                        Image(systemName: starImageName(forIndex: index))
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                            .onTapGesture { location in
                                let starWidth = (geometry.size.width - CGFloat(4 * 10)) / 5 // 计算考虑间距的星星宽度
                                let starIndex = Double(index)
                                let tapPositionInStar = location.x
                                let ratingIncrement = tapPositionInStar <= starWidth / 2 ? 0.5 : 1.0
                                let newRating = starIndex + ratingIncrement

                                if newRating == floor(newRating) {
                                    HapticFeedback.impact(.light)
                                } else {
                                    HapticFeedback.selection()
                                }
                                rating = newRating
                                print("Current Rating: \(rating)")
                            }
                    }
                }
                .frame(width: geometry.size.width, alignment: .center) // 确保 HStack 宽度充满 GeometryReader
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let dragLocation = value.location
                            let hStackWidth = geometry.size.width
                            let starWidth = (geometry.size.width - CGFloat(4 * 10)) / 5 // 拖拽时也使用考虑间距的星星宽度

                            let rawRating = dragLocation.x / starWidth
                            let snappedRating = (rawRating * 2).rounded(.toNearestOrAwayFromZero) / 2
                            let validRating = min(max(0, snappedRating), 5)

                            if validRating != rating {
                                if validRating > rating { // 只有评分增加时才震动
                                    if validRating == floor(validRating) && validRating > 0 {
                                        HapticFeedback.impact(.light)
                                    } else if validRating != floor(validRating) {
                                        HapticFeedback.selection()
                                    }
                                }
                                rating = validRating
                                print("Current Rating (Drag): \(rating)")
                            }
                        }
                )
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity, alignment: .center) // 让 GeometryReader 在父视图中居中

            Button("Clear") {
                rating = 0
                print("Rating cleared")
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity) // 让整个 VStack 在父视图中占据最大宽度
        .background(Color.white) // 为了更接近图片效果，添加白色背景
        .cornerRadius(10)      // 圆角，同上
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
}

struct StarRatingView_Previews: PreviewProvider {
    static var previews: some View {
        StarRatingView()
            .previewLayout(.sizeThatFits) // 让预览大小适应内容
            .padding()
    }
}
