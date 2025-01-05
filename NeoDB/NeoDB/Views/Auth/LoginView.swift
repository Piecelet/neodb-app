import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @Environment(\.openURL) private var openURL
    
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
            
            Button(action: {
                if let url = authService.authorizationURL {
                    openURL(url)
                }
            }) {
                HStack {
                    Image(systemName: "person.fill")
                    Text("Sign in with NeoDB")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
        }
        .padding()
    }
} 