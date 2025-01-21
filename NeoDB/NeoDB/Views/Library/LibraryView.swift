//
//  LibraryView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Kingfisher
import OSLog
import SwiftUI
import UIKit

// MARK: - Custom UISegmentedControl
private class CustomSegmentedControl: UISegmentedControl {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
}

// MARK: - UISegmentedControl Wrapper
private struct SegmentedPickerView: UIViewRepresentable {
    @Binding var selection: ShelfType
    let options: [ShelfType]
    
    func makeUIView(context: Context) -> CustomSegmentedControl {
        let segmentedControl = CustomSegmentedControl(items: options.map { $0.displayName })
        
        // Style configuration
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ]
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ]
        
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        // Set background appearance
        segmentedControl.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.5)
        segmentedControl.selectedSegmentTintColor = UIColor.systemBackground.withAlphaComponent(0.5)
        
        // Remove segment dividers
        segmentedControl.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        
        // Set initial selection
        if let index = options.firstIndex(of: selection) {
            segmentedControl.selectedSegmentIndex = index
        }
        
        segmentedControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.segmentedControlValueChanged(_:)),
            for: .valueChanged
        )
        
        return segmentedControl
    }
    
    func updateUIView(_ segmentedControl: CustomSegmentedControl, context: Context) {
        if let index = options.firstIndex(of: selection) {
            segmentedControl.selectedSegmentIndex = index
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: SegmentedPickerView
        
        init(_ parent: SegmentedPickerView) {
            self.parent = parent
        }
        
        @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
            parent.selection = parent.options[sender.selectedSegmentIndex]
        }
    }
}

struct LibraryView: View {
    // MARK: - Properties
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @StateObject private var viewModel = LibraryViewModel()
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State
    @State private var activeTab: ItemCategory.shelfAvailable = .allItems

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            shelfTypePicker
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            
            ScrollView {
                categoryFilter
                contentView
            }
            .refreshable {
                await viewModel.loadShelfItems(refresh: true)
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadShelfItems()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private var shelfTypePicker: some View {
        RoundedSegmentedPickerView(
            selection: $viewModel.selectedShelfType,
            options: ShelfType.allCases
        ) { $0.displayName }
        .onChange(of: viewModel.selectedShelfType) { newValue in
            viewModel.changeShelfType(newValue)
        }
    }

    private var categoryFilter: some View {
        ItemCategoryBarView(activeTab: $activeTab)
            .onChange(of: activeTab) { newValue in
                viewModel.selectedCategory = newValue.itemCategory
                viewModel.changeCategory(newValue.itemCategory)
            }
    }

    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if let error = viewModel.error {
            EmptyStateView(
                "Couldn't Load Library",
                systemImage: "exclamationmark.triangle",
                description: Text(viewModel.detailedError ?? error)
            )
        } else if viewModel.shelfItems.isEmpty && !viewModel.isLoading
            && !viewModel.isRefreshing
        {
            EmptyStateView(
                "No Items Found",
                systemImage: "books.vertical",
                description: Text(
                    "Add some items to your \(viewModel.selectedShelfType.displayName.lowercased()) list"
                )
            )
        } else {
            libraryContent
        }
    }

    // MARK: - Library Content
    private var libraryContent: some View {
        Group {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.shelfItems) { mark in
                    Button {
                        router.navigate(
                            to: .itemDetailWithItem(item: mark.item))
                    } label: {
                        shelfItemView(mark: mark)
                            .onAppear {
                                if mark.id == viewModel.shelfItems.last?.id {
                                    Task {
                                        await viewModel.loadNextPage()
                                    }
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.isLoading && !viewModel.isRefreshing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding()
        }
    }

    // MARK: - Shelf Item View
    private func shelfItemView(mark: MarkSchema) -> some View {
        HStack(spacing: 12) {
            coverImage(for: mark)
            itemDetails(for: mark)
            Spacer()
            chevronIcon
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func coverImage(for mark: MarkSchema) -> some View {
        KFImage(mark.item.coverImageUrl)
            .placeholder {
                placeholderView
            }
            .onFailure { _ in
                placeholderView
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(2 / 3, contentMode: .fit)
            .frame(width: 60)
    }

    private func itemDetails(for mark: MarkSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mark.item.displayTitle ?? "")
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
    }

    private var chevronIcon: some View {
        Image(systemName: "chevron.right")
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LibraryView()
            .environmentObject(Router())
            .environmentObject(AppAccountsManager())
    }
}
