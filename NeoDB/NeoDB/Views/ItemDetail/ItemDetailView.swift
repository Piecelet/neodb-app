import SwiftUI

struct ItemDetailView: View {
    @ObservedObject var viewModel: ItemDetailViewModel
    @EnvironmentObject private var router: Router
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if let item = viewModel.item {
                VStack(spacing: 0) {
                    ItemHeaderView(
                        title: viewModel.displayTitle,
                        coverImageURL: viewModel.coverImageURL,
                        rating: viewModel.rating,
                        ratingCount: viewModel.ratingCount
                    )
                    
                    Divider()
                    
                    if !viewModel.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(viewModel.description)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        
                        Divider()
                    }
                    
                    // Book-specific metadata
                    if let book = item as? EditionSchema {
                        ItemMetadataView(metadata: [
                            ("Author", book.author.joined(separator: ", ")),
                            ("Publisher", book.pubHouse ?? ""),
                            ("Published", book.pubYear.map { String($0) } ?? ""),
                            ("ISBN", book.isbn ?? ""),
                            ("Pages", book.pages.map { "\($0)" } ?? ""),
                            ("Language", book.language.joined(separator: ", "))
                        ])
                        
                        Divider()
                    }
                    
                    // Movie-specific metadata
                    if let movie = item as? MovieSchema {
                        ItemMetadataView(metadata: [
                            ("Director", movie.director.joined(separator: ", ")),
                            ("Cast", movie.actor.joined(separator: ", ")),
                            ("Year", movie.year.map { String($0) } ?? ""),
                            ("Genre", movie.genre.joined(separator: ", ")),
                            ("Duration", movie.duration ?? ""),
                            ("Language", movie.language.joined(separator: ", "))
                        ])
                        
                        Divider()
                    }
                    
                    // TV Show-specific metadata
                    if let show = item as? TVShowSchema {
                        ItemMetadataView(metadata: [
                            ("Director", show.director.joined(separator: ", ")),
                            ("Cast", show.actor.joined(separator: ", ")),
                            ("Year", show.year.map { String($0) } ?? ""),
                            ("Genre", show.genre.joined(separator: ", ")),
                            ("Episodes", show.episodeCount.map { String($0) } ?? ""),
                            ("Language", show.language.joined(separator: ", "))
                        ])
                        
                        Divider()
                    }
                    
                    // Game-specific metadata
                    if let game = item as? GameSchema {
                        ItemMetadataView(metadata: [
                            ("Developer", game.developer.joined(separator: ", ")),
                            ("Publisher", game.publisher.joined(separator: ", ")),
                            ("Platform", game.platform.joined(separator: ", ")),
                            ("Genre", game.genre.joined(separator: ", ")),
                            ("Release", game.releaseDate.map { String($0) } ?? "")
                        ])
                        
                        Divider()
                    }
                    
                    // Album-specific metadata
                    if let album = item as? AlbumSchema {
                        ItemMetadataView(metadata: [
                            ("Artist", album.artist.joined(separator: ", ")),
                            ("Genre", album.genre.joined(separator: ", ")),
                            ("Company", album.company.joined(separator: ", ")),
                            ("Release", album.releaseDate.map { String($0) } ?? ""),
                            ("Duration", album.duration.map { String($0) } ?? "")
                        ])
                        
                        Divider()
                    }
                    
                    // Podcast-specific metadata
                    if let podcast = item as? PodcastSchema {
                        ItemMetadataView(metadata: [
                            ("Host", podcast.host.joined(separator: ", ")),
                            ("Genre", podcast.genre.joined(separator: ", ")),
                            ("Language", podcast.language.joined(separator: ", "))
                        ])
                        
                        Divider()
                    }
                    
                    // Performance-specific metadata
                    if let performance = item as? PerformanceSchema {
                        ItemMetadataView(metadata: [
                            ("Director", performance.director.joined(separator: ", ")),
                            ("Cast", performance.performer.joined(separator: ", ")),
                            ("Genre", performance.genre.joined(separator: ", ")),
                            ("Language", performance.language.joined(separator: ", ")),
                            ("Opening", performance.openingDate ?? ""),
                            ("Closing", performance.closingDate ?? "")
                        ])
                        
                        Divider()
                    }
                    
                    // Actions
                    ItemActionsView(item: ItemSchema(
                        title: item.title,
                        description: item.description,
                        localizedTitle: item.localizedTitle,
                        localizedDescription: item.localizedDescription,
                        coverImageUrl: item.coverImageUrl,
                        rating: item.rating,
                        ratingCount: item.ratingCount,
                        id: item.id,
                        type: item.type,
                        uuid: item.uuid,
                        url: item.url,
                        apiUrl: item.apiUrl,
                        category: item.category,
                        parentUuid: item.parentUuid,
                        displayTitle: item.displayTitle,
                        externalResources: item.externalResources,
                        brief: nil
                    ))
                }
            } else {
                EmptyStateView(
                    "Item Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text("The requested item could not be found or has been removed.")
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(viewModel: ItemDetailViewModel(itemDetailService: ItemDetailService(authService: AuthService())))
            .environmentObject(Router())
    }
} 