# Network Layer Migration

## Recent Changes (2024-01-14)

### Security Improvements

1. OAuth Token Exchange
- Migrated token exchange logic from `AuthService` to `OauthEndpoint`
- Implemented token exchange using `queryItems` instead of request body
- Added proper Accept header for JSON responses

2. Instance URL Handling
- Added `cleanInstanceHost` static function in `AppClient` for secure URL handling
- Handles both direct hostnames and full URLs
- Ensures consistent key generation for keychain storage
```swift
private static func cleanInstanceHost(from instance: String) -> String {
    if let components = URLComponents(string: instance),
       let host = components.host {
        return host
    } else if let components = URLComponents(string: "https://\(instance)"),
              let host = components.host {
        return host
    }
    return instance.lowercased()
}
```

3. Logging Security
- Removed sensitive information from logs (tokens, credentials)
- Simplified error messages to avoid exposing internal details
- Added structured logging for key operations while maintaining privacy

### Code Organization

1. Endpoint Definitions
- Created `OauthEndpoint` for authentication-related requests
- Implemented `NetworkEndpoint` protocol for type-safe requests
- Separated OAuth token exchange logic from account management

2. Client Management
- Improved `AppClient` key generation using `cleanInstanceHost`
- Unified instance URL handling across the application
- Simplified client registration and retrieval logic

3. Account Management
- Simplified `AppAccount` keychain operations
- Improved error handling and logging
- Maintained backward compatibility with existing stored data

### Key Improvements

1. Security
- Safe URL parsing and host extraction
- Secure keychain key generation
- Privacy-focused logging

2. Maintainability
- Consistent URL handling across the app
- Clear separation of concerns
- Type-safe network requests

3. Reliability
- Improved error handling
- Better keychain key management
- More robust client registration process

## Core Network Components

### NetworkEndpoint Protocol
- Unified interface for network requests
- Supports basic properties: path, method, queryItems, body
- JSON/URL-encoded format support via bodyContentType
- Default implementations for common configurations

### NetworkClient
- Handles network request execution
- Async/await support
- Unified error handling
- Automatic URL construction and header management
- JSON decoding support
- Integrated logging system

## App Registration Flow

### Models
- `AppClientResponse`: API response model
  - Complete client registration information
  - Snake case handling via CodingKeys
  - Codable protocol support

### Endpoints
- `AppsEndpoints`: Application registration endpoints
  - Implements NetworkEndpoint protocol
  - Handles app registration requests
  - JSON request body support

### Client Management
- `AppClient`: Client credentials management
  - Complete storage of registration information
  - Secure storage using KeychainSwift
  - CRUD operations support
  - Integrated logging system
  - Smart instance URL handling (using URLComponents)

### Security
- KeychainKeys for key management
  - Type-safe key handling
  - Unified prefix management
  - Instance isolation support

## Logging System
- OSLog integration
- Module-based categorization (network, auth, managers, etc.)
- Multiple log levels (debug, error)
- Contextual information (instance, operation type, etc.)

## Improvements
1. More modular and testable network layer
2. Enhanced type safety
3. Unified error handling
4. Comprehensive logging
5. Secure credential storage
6. Improved URL handling

## Next Steps
1. Implement OAuth authentication flow
2. Add request rate limiting
3. Implement request caching
4. Add request retry mechanism
5. Enhance error reporting
