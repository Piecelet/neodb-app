//
//  ItemTitleView.swift
//  NeoDB
//
//  Created by citron on 1/25/25.
//

import SwiftUI

enum ItemTitleMode {
    case title
    case titleAndSubtitle
}

enum ItemTitleSize {
    case medium
    case large

    var titleFont: Font {
        switch self {
        case .medium:
            return .headline
        case .large:
            return .title2
        }
    }

    var titleWeight: Font.Weight {
        switch self {
        case .medium:
            return .regular
        case .large:
            return .bold
        }
    }
    

    var subtitleFont: Font {
        switch self {
        case .medium:
            return .subheadline
        case .large:
            return .headline
        }
    }

    var lineLimit: Int {
        switch self {
        case .medium:
            return 2
        case .large:
            return 3
        }
    }
}

struct ItemTitleView: View {
    let item: (any ItemProtocol)?
    let mode: ItemTitleMode
    let size: ItemTitleSize
    var alignment: HorizontalAlignment = .leading
    
    var displayTitle: AttributedString {
        switch mode {
        case .title:
            var title = AttributedString(item?.displayTitle ?? "")
            if let movie = item as? MovieSchema, let year = movie.year {
                var yearString = AttributedString(" (\(year))")
                yearString.foregroundColor = .secondary
                title += yearString
            }
            return title
        case .titleAndSubtitle:
            return AttributedString(item?.displayTitle ?? item?.title ?? "")
        }
    }
    
    var originalTitle: String {
        var title = ""
        var year = ""
        switch item {
        case let book as EditionSchema:
            title = book.origTitle ?? ""
        case let movie as MovieSchema:
            title = movie.origTitle ?? ""
            if let movieYear = movie.year {
                year = " (\(movieYear))"
            }
        case let tv as TVShowSchema:
            title = tv.origTitle ?? ""
        case let performance as PerformanceSchema:
            title = performance.origTitle ?? ""
        default:
            break
        }
        if title != String(self.displayTitle.characters) {
            return (title + year).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return year.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var body: some View {
        Group {
            switch mode {
            case .title:
                Text(displayTitle)
                    .font(size.titleFont)
                    .lineLimit(size.lineLimit)
                    .multilineTextAlignment(textAlignment)
                    .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
            case .titleAndSubtitle:
                VStack(alignment: alignment, spacing: 2) {
                    Text(displayTitle)
                        .font(size.titleFont)
                        .lineLimit(size.lineLimit)
                        .fontWeight(size.titleWeight)
                        .multilineTextAlignment(textAlignment)
                    if !originalTitle.isEmpty {
                        Text(originalTitle)
                            .font(size.subtitleFont)
                            .lineLimit(size.lineLimit)
                            .multilineTextAlignment(textAlignment)
                    }
                }
                .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
            }
        }
        .enableInjection()
    }
    
    private var textAlignment: TextAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        default:
            return .leading
        }
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    VStack(spacing: 20) {
        ItemTitleView(
            item: ItemSchema.preview,
            mode: .title,
            size: .medium
        )

        ItemTitleView(
            item: ItemSchema.preview,
            mode: .titleAndSubtitle,
            size: .large,
            alignment: .center
        )
        
        ItemTitleView(
            item: ItemSchema.preview,
            mode: .title,
            size: .medium,
            alignment: .trailing
        )
    }
    .padding()
}
