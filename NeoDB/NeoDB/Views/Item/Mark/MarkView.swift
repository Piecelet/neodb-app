//
//  MarkView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI

struct MarkView: View {
    @StateObject private var viewModel: MarkViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @State private var showAdvanced = false
    @State private var detent: PresentationDetent = .medium
    
    init(item: any ItemProtocol, mark: MarkSchema? = nil) {
        _viewModel = StateObject(wrappedValue: MarkViewModel(item: item, mark: mark))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar
            HStack {
                Text(viewModel.title)
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }
            }
            .padding()
            
            Form {
                // Shelf Type
                Section {
                    HStack(spacing: 16) {
                        ForEach(ShelfType.allCases, id: \.self) { type in
                            Button {
                                viewModel.shelfType = type
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: type.iconName)
                                        .font(.title2)
                                    Text(type.displayName)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(viewModel.shelfType == type ? .primary : .secondary)
                            }
                            .buttonStyle(.borderless)

                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Rating
                Section {
                    HStack {
                        ForEach(1...5, id: \.self) { score in
                            let rating = Double(score)
                            HStack(spacing: 0) {
                                // Full star
                                Button {
                                    viewModel.rating = score * 2
                                } label: {
                                    Image(systemName: rating <= (Double(viewModel.rating ?? 0) / 2) ? "star.fill" : "star")
                                        .foregroundStyle(rating <= (Double(viewModel.rating ?? 0) / 2) ? .yellow : .gray)
                                }
                                
                                // Half star
                                Button {
                                    viewModel.rating = score * 2 - 1
                                } label: {
                                    Image(systemName: rating - 0.5 <= (Double(viewModel.rating ?? 0) / 2) ? "star.leadinghalf.filled" : "star")
                                        .foregroundStyle(rating - 0.5 <= (Double(viewModel.rating ?? 0) / 2) ? .yellow : .gray)
                                }
                            }
                        }
                        
                        if viewModel.rating != nil {
                            Button {
                                viewModel.rating = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Comment
                Section {
                    TextEditor(text: $viewModel.comment)
                        .frame(minHeight: 100)
                } header: {
                    Text("Comment")
                } footer: {
                    Text("Optional")
                }
                
                // Advanced Options
                Section {
                    DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
                        Toggle("Public", isOn: $viewModel.isPublic)
                        Toggle("Share to Fediverse", isOn: $viewModel.postToFediverse)
                        
                        Toggle("Use Current Time", isOn: $viewModel.useCurrentTime)
                        
                        if !viewModel.useCurrentTime {
                            DatePicker(
                                "Created Time",
                                selection: $viewModel.createdTime,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        }
                    }
                }
                
                // Delete Button
                if viewModel.existingMark != nil {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteMark()
                            }
                        } label: {
                            Text("Delete Mark")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            
            // Bottom Save Button
            VStack(spacing: 16) {
                Button {
                    Task {
                        await viewModel.saveMark()
                    }
                } label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(.ultraThinMaterial)
        }
        .background(.ultraThinMaterial)
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .onChange(of: viewModel.isDismissed) { dismissed in
            if dismissed {
                dismiss()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            viewModel.accountsManager = accountsManager
        }
    }
}

#Preview {
    MarkView(item: ItemSchema.preview)
        .environmentObject(AppAccountsManager())
}

