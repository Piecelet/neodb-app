//
//  MastodonLoginView.swift
//  NeoDB
//
//  Created by citron on 2/10/25.
//

import AuthenticationServices
import SwiftUI

struct MastodonLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.webAuthenticationSession) private
        var webAuthenticationSession
    @EnvironmentObject private var accountsManager: AppAccountsManager

    @StateObject private var viewModel = MastodonLoginViewModel()

    // Animation states
    @State private var inputScale = 0.9
    @State private var contentOpacity = 0.0

    var body: some View {
        VStack(spacing: 0) {
            stepperView
            //                .ignoresSafeArea(edges: .top)

            Form {
                if viewModel.currentStep == 1 {
                    mastodonInstanceStep
                } else {
                    neodbInstanceStep
                }
            }
            .scrollContentBackground(.hidden)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sign In with Mastodon")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", systemSymbol: .chevronLeft) {
                    dismiss()
                }
                .labelStyle(.iconOnly)
            }
        }
        .sheet(isPresented: $viewModel.showInstanceInput) {
            InstanceInputView(
                selectedInstance: accountsManager.currentAccount.instance
            ) { newInstance in
                viewModel.updateNeoDBInstance(newInstance)
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .task {
            viewModel.accountsManager = accountsManager

            // Trigger animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                inputScale = 1.0
                contentOpacity = 1.0
            }

            // Load initial instances
            await viewModel.loadInitialInstances()
        }
        .enableInjection()
    }

    // MARK: - Subviews
    private var stepperView: some View {
        VStack(spacing: 16) {
            StepIndicator(
                step: 1,
                title: viewModel.currentStep == 1
                    ? "Step 1: Mastodon" : viewModel.mastodonInstance,
                description: "Choose your Mastodon instance",
                isActive: viewModel.currentStep == 1,
                isCompleted: viewModel.currentStep > 1
            )

            // Vertical connector line
            //            Rectangle()
            //                .frame(width: 1, height: 24)
            //                .foregroundStyle(.secondary.opacity(0.3))

            StepIndicator(
                step: 2,
                title: "Step 2: NeoDB",
                description: "Select your NeoDB instance",
                isActive: viewModel.currentStep == 2,
                isCompleted: viewModel.currentStep > 2
            )
        }
        //        .padding(.bottom, 8)
        .padding(.leading, 36)
    }

    private var mastodonInstanceStep: some View {
        Group {
            Section {
                TextField("mastodon.social", text: $viewModel.mastodonInstance)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.mastodonInstance) { _ in
                        viewModel.searchInstances()
                    }
            }

            Section {
                actionButton
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            // Instance Detail
            if let instance = viewModel.selectedMastodonInstance {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .bottom,spacing: 4) {
                            Text(instance.title)
                                .font(.headline)
                            Text(viewModel.mastodonInstance)
                                .foregroundStyle(.secondary)
                        }
                        Text(instance.shortDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Users")
                        Spacer()
                        Text("\(instance.stats.userCount) users")
                    }
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    
                    HStack {
                        Text("Posts")
                        Spacer()
                        Text("\(instance.stats.statusCount) posts")
                    }
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    
                    HStack {
                        Text("Links")
                        Spacer()
                        Text("\(instance.stats.domainCount) links")
                    }
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                } header: {
                    Text("Instance Details")
                }

                Section {
                    if let rules = instance.rules, !rules.isEmpty {
                        ForEach(Array(rules.enumerated()), id: \.element.id) { index, rule in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: index <= 50 ? "\(index + 1).circle" : "info.circle")
                                    .padding(.top, 4)
                                    .foregroundStyle(.accent)
                                Text(rule.text)
                                    .font(.subheadline)
                                    .padding(.vertical, 4)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 11, leading: 11, bottom: 11, trailing: 20))
                        }
                    
                } header: {
                    Text("Instance Rules")
                }
            }

            // Instance List
            if !viewModel.filteredInstances.isEmpty
                && viewModel.selectedMastodonInstance == nil
            {
                Section {
                    ForEach(viewModel.filteredInstances) { instance in
                        Button {
                            viewModel.selectInstance(instance)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(instance.domain)
                                    Spacer()
                                    Text("\(instance.totalUsers) users")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                                Text(instance.description)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    Text("Popular Instances")
                }
            }
        }
    }

    private struct StatView: View {
        let title: String
        let value: Int

        var body: some View {
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.formatted())
                    .font(.subheadline.bold())
            }
            .enableInjection()
        }

        #if DEBUG
            @ObserveInjection var forceRedraw
        #endif
    }

    private var neodbInstanceStep: some View {
        Group {
            Section {
                HStack {
                    Text(accountsManager.currentAccount.instance)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Change") {
                        withAnimation {
                            viewModel.showInstanceInput = true
                        }
                    }
                }
            }
            Section {
                actionButton
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section {
                Button(role: .cancel) {
                    withAnimation {
                        viewModel.currentStep = 1
                    }
                } label: {
                    Text("Back to Mastodon Instance")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var actionButton: some View {
        Button(action: {
            if viewModel.currentStep == 1 {
                if viewModel.validateAndContinue() {
                    withAnimation {
                        viewModel.currentStep = 2
                    }
                }
            } else {
                Task {
                    await viewModel.authenticate(
                        using: webAuthenticationSession)
                }
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(viewModel.currentStep == 1 ? "Continue" : "Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(
            viewModel.isLoading
                || (viewModel.currentStep == 1
                    && viewModel.mastodonInstance.isEmpty)
        )
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

// MARK: - Step Indicator
struct StepIndicator: View {
    let step: Int
    let title: String
    let description: String
    let isActive: Bool
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(backgroundColor)
                .frame(width: 28, height: 28)
                .overlay {
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(step)")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(isActive ? .white : .secondary)
                    }
                }
                .scaleEffect(isActive ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isActive)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isActive ? .primary : .secondary)

                if isActive {
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private var backgroundColor: Color {
        if isCompleted {
            return .accentColor.opacity(0.6)
        } else if isActive {
            return .accentColor
        } else {
            return Color(.systemGray5)
        }
    }
}
