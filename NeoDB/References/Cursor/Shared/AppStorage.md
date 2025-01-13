# AppStorage Implementation

## Overview
Implements a strongly typed key system for SwiftUI's `@AppStorage` property wrapper, providing type-safe access to `UserDefaults` values.

## Implementation Details

### Key Definition
```swift
struct AppStorageKeys {
    init() { }
}

extension AppStorageKeys {
    var customInstance: AppStorageKey<String> { .init("custom_instance", defaultValue: "") }
}
```

### Key Structure
```swift
struct AppStorageKey<Value> {
    let name: String
    let defaultValue: Value
    
    init(_ name: String, defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}
```

### AppStorage Extension
```swift
extension AppStorage where Value == String {
    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        self.init(strongKeyPath, store: nil)
    }
}
```

## Usage Example
```swift
struct ExampleView: View {
    @AppStorage(\.customInstance) private var customInstance: String
    
    var body: some View {
        TextField("Instance", text: $customInstance)
    }
}
```

## Key Features
1. Type Safety
   - Compile-time type checking for storage values
   - Prevents runtime type mismatches

2. Centralized Key Management
   - All keys defined in one location
   - Easy to maintain and extend

3. Default Values
   - Each key includes a default value
   - Ensures consistent initialization

4. SwiftUI Integration
   - Seamless integration with SwiftUI's property wrapper system
   - Maintains reactive updates
