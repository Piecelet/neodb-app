# 202207041909 AppStorage extension for strongly typed keys
#appstorage #swiftui 

The `@AppStorage` property wrapper for observable access to `UserDefaults` keys is stringified.

To get a strongly typed key access, I oriented myself on the `@Environment(\.keyPath)` wrapper and my experience with `SwiftyUserDefaults` and its subscript-based access.

    // Use defaultValue from the key:
    @AppStorage(\.showOnboarding) var showOnboarding
    
    // Pass explicit wrappedValue to the initializer:
    @AppStorage(\.showOnboarding) var showOnboarding: Bool = false

In the app using the code below, declare strong keys in an extension to get the key paths. (The empty struct initializer is a no-op.)

```swift
struct AppStorageKeys { init() { } }

extension AppStorageKeys {
    var showOnboarding: AppStorageKey<Bool> { .init("show_onboarding", defaultValue: true) }
    var enableSounds: AppStorageKey<Bool> { .init("enable_sounds", defaultValue: true) }
}
```

## AppStorageKey

The basic type is `AppStorageKey<V>`.  It matches `AppStroage<V>`, which has no protocol requirement on the value type, so it's pretty simple:

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

## AppStorage property wrapper extensions

The `AppStorage` property wrapper itself has individual initializers for all supported types, so we need to write extensions for all of them, too.

Here's one for `Bool`:

```swift
extension AppStorage where Value == Bool {
    init(wrappedValue: Bool, strongKey: AppStorageKey<Value>, store: UserDefaults? = nil) {
        self.init(wrappedValue: wrappedValue, strongKey.name, store: store)
    }

    /// Testing seam.
    init(wrappedValue: Value,
         strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>,
         store: UserDefaults? = nil) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]
        self.init(wrappedValue: wrappedValue, strongKey: strongKey, store: store)
    }

    init(wrappedValue: Value,
         _ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        self.init(wrappedValue: wrappedValue, strongKeyPath: strongKeyPath, store: nil)
    }

    /// Testing seam.
    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>, store: UserDefaults? = nil) {
        let strongKey = AppStorageKeys()[keyPath: strongKeyPath]
        self.init(wrappedValue: strongKey.defaultValue, strongKey: strongKey, store: store)
    }

    init(_ strongKeyPath: KeyPath<AppStorageKeys, AppStorageKey<Value>>) {
        self.init(strongKeyPath, store: nil)
    }
}
```

### Unit Tests

```swift
class AppStorageKeysTests: XCTestCase {
    var testDefaultsSuiteName: String { "com.foobar.app-defaults-test" }
    var testDefaults: UserDefaults { .init(suiteName: testDefaultsSuiteName)! }

    private func clearTestDefaults() {
        let keys = testDefaults.dictionaryRepresentation().keys
        keys.forEach(testDefaults.removeObject(forKey:))
        UserDefaults.standard.removeSuite(named: testDefaultsSuiteName)
    }

    override func setUpWithError() throws { clearTestDefaults() }
    override func tearDownWithError() throws { clearTestDefaults() }

    func testBoolKey() throws {
        @AppStorage(wrappedValue: false, AppStorageKeys().showOnboarding.name, store: testDefaults)
        var regularStorage: Bool

        @AppStorage(wrappedValue: false, strongKey: AppStorageKeys().showOnboarding, store: testDefaults)
        var keyedStorage: Bool

        @AppStorage(wrappedValue: false, strongKeyPath: \.showOnboarding, store: testDefaults)
        var convenienceKeyPathStorage: Bool

        @AppStorage(\.showOnboarding, store: testDefaults)
        var defaultValueStorage: Bool

        XCTAssertTrue(AppStorageKeys().showOnboarding.defaultValue,
                      "Default value is not the same as we use as wrapped value for all other keys, so we actually note a difference")
        XCTAssertTrue(defaultValueStorage)

        XCTAssertFalse(regularStorage)
        XCTAssertFalse(keyedStorage)
        XCTAssertFalse(convenienceKeyPathStorage)

        testDefaults.set(true, forKey: AppStorageKeys().showOnboarding.name)

        XCTAssertTrue(regularStorage)
        XCTAssertTrue(keyedStorage)
        XCTAssertTrue(convenienceKeyPathStorage)
        XCTAssertTrue(defaultValueStorage)

        testDefaults.set(false, forKey: AppStorageKeys().showOnboarding.name)

        XCTAssertFalse(regularStorage)
        XCTAssertFalse(keyedStorage)
        XCTAssertFalse(convenienceKeyPathStorage)
        XCTAssertFalse(defaultValueStorage)
    }
}
```
