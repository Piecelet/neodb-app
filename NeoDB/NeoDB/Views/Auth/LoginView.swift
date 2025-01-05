import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @Environment(\.openURL) private var openURL
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var instanceUrl: String = "neodb.social"
    @State private var showInstanceInput = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image("neodb-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            Text("Welcome to NeoDB")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Track and share your books, movies, music, and more")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Instance")
                    .font(.headline)
                
                HStack {
                    Text(authService.currentInstance)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Change") {
                        showInstanceInput = true
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: {
                Task {
                    do {
                        try await authService.registerApp()
                        if let url = authService.authorizationURL {
                            openURL(url)
                        } else {
                            errorMessage = "Failed to create authorization URL"
                            showError = true
                        }
                    } catch AuthError.registrationFailed(let message) {
                        errorMessage = "Registration failed: \(message)"
                        showError = true
                    } catch AuthError.tokenExchangeFailed(let message) {
                        errorMessage = "Authentication failed: \(message)"
                        showError = true
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }) {
                HStack {
                    if authService.isRegistering {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.fill")
                        Text("Sign in with NeoDB")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(authService.isRegistering)
            .padding(.horizontal)
        }
        .padding()
        .alert("Error", isPresented: $showError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
        .sheet(isPresented: $showInstanceInput) {
            NavigationStack {
                InstanceInputView(instanceUrl: instanceUrl) { newInstance in
                    do {
                        try authService.switchInstance(newInstance)
                        instanceUrl = newInstance
                        showInstanceInput = false
                    } catch {
                        errorMessage = "Invalid instance URL"
                        showError = true
                    }
                }
                .navigationTitle("Change Instance")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showInstanceInput = false
                    }
                )
            }
            .presentationDetents([.height(200)])
        }
    }
}

struct InstanceInputView: View {
    @State var instanceUrl: String
    let onSubmit: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Enter the URL of your NeoDB instance")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("Instance URL", text: $instanceUrl)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.URL)
                .submitLabel(.done)
                .onSubmit {
                    onSubmit(instanceUrl)
                }
            
            Button("Connect") {
                onSubmit(instanceUrl)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
} 