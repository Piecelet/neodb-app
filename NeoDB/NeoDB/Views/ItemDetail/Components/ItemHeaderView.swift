import SwiftUI
import Kingfisher

struct ItemHeaderView: View {
    let title: String
    let coverImageURL: URL?
    let rating: String
    let ratingCount: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Cover Image
            KFImage(coverImageURL)
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(2/3, contentMode: .fit)
                }
                .onFailure { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(2/3, contentMode: .fit)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)
            
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Rating
            if rating != "N/A" {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(rating)
                            .fontWeight(.semibold)
                    }
                    
                    if !ratingCount.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(ratingCount)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
        }
        .padding()
    }
}

#Preview {
    ItemHeaderView(
        title: "Sample Title",
        coverImageURL: URL(string: "https://example.com/image.jpg"),
        rating: "4.5",
        ratingCount: "1,234 ratings"
    )
} 