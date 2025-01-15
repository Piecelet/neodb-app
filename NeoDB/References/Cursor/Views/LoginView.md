# LoginView Changes

## Instance Selection and Persistence

### InstanceInputView Updates
- Added `@AppStorage(\.customInstance)` to persist custom instance input
- Added checkmark indicator for both predefined and custom instances
- Improved visual feedback for selected instance

### Implementation Details
```swift
struct InstanceInputView: View {
    @State private var selectedInstance: String
    @AppStorage(\.customInstance) private var customInstance: String
    
    // Custom instance section with checkmark
    TextField("instance.social", text: $customInstance)
        .overlay(
            HStack {
                Spacer()
                if selectedInstance == customInstance && !customInstance.isEmpty {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        )
}
```

### Key Features
1. Persistent Storage
   - Custom instance URL is now saved between app launches
   - Uses type-safe AppStorage implementation

2. Visual Consistency
   - Checkmark indicator for both predefined and custom instances
   - Consistent visual feedback across all instance selection options

3. User Experience
   - Clear indication of currently selected instance
   - Seamless transition between predefined and custom instances
