import Foundation
import AuthenticationServices

public class AuthenticationService: NSObject {
    private let api: NeoDBAPI
    private var webAuthSession: ASWebAuthenticationSession?
    private let callbackURLScheme = "neodb"
    
    public init(api: NeoDBAPI) {
        self.api = api
    }
    
    public func authenticate(
        clientId: String,
        clientSecret: String
    ) async throws -> NeoDBAccessToken {
        guard let authURL = api.getAuthorizationURL(
            clientId: clientId,
            redirectURI: "\(callbackURLScheme)://oauth"
        ) else {
            throw NeoDBAPIError.invalidURL
        }
        
        let code = try await authorizeWithWebSession(url: authURL)
        
        return try await api.exchangeCodeForToken(
            clientId: clientId,
            clientSecret: clientSecret,
            code: code,
            redirectURI: "\(callbackURLScheme)://oauth"
        )
    }
    
    private func authorizeWithWebSession(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let authSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value
                else {
                    continuation.resume(throwing: NeoDBAPIError.unknown)
                    return
                }
                
                continuation.resume(returning: code)
            }
            
            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = true
            
            self.webAuthSession = authSession
            authSession.start()
        }
    }
}

extension AuthenticationService: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
} 