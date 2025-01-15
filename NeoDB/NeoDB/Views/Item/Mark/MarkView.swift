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
    
    init(item: any ItemProtocol, mark: MarkSchema? = nil) {
        _viewModel = StateObject(wrappedValue: MarkViewModel(item: item, mark: mark))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Shelf Type
                Section {
                    Picker("Shelf", selection: $viewModel.shelfType) {
                        ForEach(ShelfType.allCases, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                }
                
                // Rating
                Section {
                    HStack {
                        Text("Rating")
                        Spacer()
                        if let rating = viewModel.rating {
                            Text("\(rating)/10")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        ForEach(1...10, id: \.self) { score in
                            Button {
                                if viewModel.rating == score {
                                    viewModel.rating = nil
                                } else {
                                    viewModel.rating = score
                                }
                            } label: {
                                Image(systemName: score <= (viewModel.rating ?? 0) ? "star.fill" : "star")
                                    .foregroundStyle(score <= (viewModel.rating ?? 0) ? .yellow : .gray)
                            }
                        }
                    }
                    .buttonStyle(.plain)
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
                
                // Visibility
                Section {
                    Toggle("Public", isOn: $viewModel.isPublic)
                } footer: {
                    Text("Public marks will be visible to other users")
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
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveMark()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
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
}

#Preview {
    MarkView(item: ItemSchema.preview)
        .environmentObject(AppAccountsManager())
}

