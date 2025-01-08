import SwiftUI
import OSLog

struct ShelfItemView: View {
    let mark: MarkSchema
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover Image
            AsyncImage(url: URL(string: mark.item.coverImageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(2/3, contentMode: .fit)
                        .frame(width: 60)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(2/3, contentMode: .fit)
                        .frame(width: 60)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mark.item.displayTitle)
                    .font(.headline)
                    .lineLimit(2)
                
                if let rating = mark.ratingGrade {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("\(rating)/10")
                    }
                    .font(.subheadline)
                }
                
                if !mark.tags.isEmpty {
                    Text(mark.tags.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#if DEBUG
struct ShelfItemView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ShelfItemView(mark: .preview)
        }
    }
}

extension MarkSchema {
    static var preview: MarkSchema {
        MarkSchema(
            shelfType: .wishlist,
            visibility: 0,
            item: ItemSchema(
                title: "Sample Book",
                description: "A sample book description",
                localizedTitle: [],
                localizedDescription: [],
                coverImageUrl: nil,
                rating: 4.5,
                ratingCount: 100,
                id: "1",
                type: "book",
                uuid: "1",
                url: "https://example.com",
                apiUrl: "https://api.example.com",
                category: .book,
                parentUuid: nil,
                displayTitle: "Sample Book",
                externalResources: nil
            ),
            createdTime: Date(),
            commentText: "Great book!",
            ratingGrade: 8,
            tags: ["fiction", "mystery"]
        )
    }
}
#endif 
