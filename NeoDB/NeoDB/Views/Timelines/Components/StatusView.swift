//
//  StatusView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI
import Kingfisher
import HTML2Markdown
import MarkdownUI

struct StatusView: View {
    let status: MastodonStatus
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var router: Router
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Button {
//                    router.navigate(to: .userProfile(id: status.account.id))
                } label: {
                    KFImage(status.account.avatar)
                        .placeholder {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 44, height: 44)
                        }
                        .onFailure { _ in
                            Image(systemName: "person.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                                .font(.system(size: 44))
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.account.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("@\(status.account.username)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(status.createdAt.formatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Content
            HTMLContentView(htmlContent: status.content)
                .textSelection(.enabled)
            
            // Media
            if !status.mediaAttachments.isEmpty {
                mediaGrid
            }
            
            // Footer
            if !status.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(status.tags, id: \.name) { tag in
                            Text("#\(tag.name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Stats
            HStack(spacing: 16) {
                Label("\(status.repliesCount)", systemImage: "bubble.right")
                Label("\(status.reblogsCount)", systemImage: "arrow.2.squarepath")
                Label("\(status.favouritesCount)", systemImage: "star")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private var mediaGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: min(status.mediaAttachments.count, 2))
        
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(status.mediaAttachments) { attachment in
                KFImage(attachment.url)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fill)
                    }
                    .onFailure { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fill)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
} 
