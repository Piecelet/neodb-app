# Network System Implementation

## Overview
NeoDB uses a unified network system based on URLSession for all API requests. The system is designed to be type-safe, protocol-oriented, and easily extensible.

## Core Components

### NetworkEndpoint Protocol
```swift
protocol NetworkEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
    var headers: [String: String]? { get }
}
```

### NetworkClient
- Handles all network requests
- Manages base URL composition
- Handles authentication tokens
- Provides unified error handling
- Includes comprehensive logging

## Error Handling
```swift
enum NetworkError: Error {
    case invalidURL
    case unauthorized
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
}
```

## Endpoints
Organized by feature area:

### User Endpoints
```swift
enum UserEndpoints {
    case me
}
```

### Auth Endpoints
```swift
enum AuthEndpoints {
    case authorize(clientId: String, redirectUri: String, scope: String)
    case token(code: String, clientId: String, clientSecret: String, redirectUri: String)
    case revokeToken(token: String)
}
```

## Usage Example
```swift
class UserService {
    private let networkClient: NetworkClient
    
    func getCurrentUser() async throws -> User {
        try await networkClient.fetch(UserEndpoints.me, type: User.self)
    }
}
```

## Features
- Type-safe request/response handling
- Automatic URL composition
- Token-based authentication
- Comprehensive error handling
- Detailed logging for debugging
- Support for query parameters and custom headers

## Best Practices
1. Create endpoint enums for each feature area
2. Use meaningful error types
3. Include appropriate logging
4. Handle unauthorized states
5. Validate responses

## Recent Changes
- Moved URL composition to NetworkClient
- Added detailed logging for debugging
- Standardized error handling
- Implemented endpoint-specific configurations 