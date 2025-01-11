# AppAccount.swift
```swift
import SwiftUI
import Timeline
import Network
import KeychainSwift
import Models

struct AppAccount: Codable, Identifiable {
  let server: String
  let oauthToken: OauthToken?
  
  var id: String {
    key
  }
  
  var key: String {
    if let oauthToken {
      return "\(server):\(oauthToken.createdAt)"
    } else {
      return "\(server):anonymous:\(Date().timeIntervalSince1970)"
    }
  }
  
  func save() throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(self)
    let keychain = KeychainSwift()
    keychain.set(data, forKey: key)
  }
  
  func delete() {
    KeychainSwift().delete(key)
  }
  
  static func retrieveAll() throws -> [AppAccount] {
    let keychain = KeychainSwift()
    let decoder = JSONDecoder()
    let keys = keychain.allKeys
    var accounts: [AppAccount] = []
    for key in keys {
      if let data = keychain.getData(key) {
        let account = try decoder.decode(AppAccount.self, from: data)
        accounts.append(account)
      }
    }
    return accounts
  }
  
  static func deleteAll() {
    let keychain = KeychainSwift()
    let keys = keychain.allKeys
    for key in keys {
      keychain.delete(key)
    }
  }
}
```


# AppAccountsManager.swift

```swift
import SwiftUI
import Network

class AppAccountsManager: ObservableObject {
  @AppStorage("latestCurrentAccountKey") static public var latestCurrentAccountKey: String = ""
  
  @Published var currentAccount: AppAccount {
    didSet {
      Self.latestCurrentAccountKey = currentAccount.id
      currentClient = .init(server: currentAccount.server,
                            oauthToken: currentAccount.oauthToken)
    }
  }
  @Published var availableAccounts: [AppAccount]
  @Published var currentClient: Client
  
  init() {
    var defaultAccount = AppAccount(server: IceCubesApp.defaultServer, oauthToken: nil)
    do {
      let keychainAccounts = try AppAccount.retrieveAll()
      availableAccounts = keychainAccounts
      if let currentAccount = keychainAccounts.first(where: { $0.id == Self.latestCurrentAccountKey }) {
        defaultAccount = currentAccount
      } else {
        defaultAccount = keychainAccounts.last ?? defaultAccount
      }
    } catch {
      availableAccounts = [defaultAccount]
    }
    currentAccount = defaultAccount
    currentClient = .init(server: defaultAccount.server, oauthToken: defaultAccount.oauthToken)
  }
  
  func add(account: AppAccount) {
    do {
      try account.save()
      availableAccounts.append(account)
      currentAccount = account
    } catch { }
  }
  
  func delete(account: AppAccount) {
    availableAccounts.removeAll(where: { $0.id == account.id })
    account.delete()
    if currentAccount.id == account.id {
      currentAccount = availableAccounts.first ?? AppAccount(server: IceCubesApp.defaultServer, oauthToken: nil)
    }
  }
}
```


# AppAccountView.swift
```swift
import SwiftUI
import DesignSystem

struct AppAccountView: View {
  @EnvironmentObject var appAccounts: AppAccountsManager
  @StateObject var viewModel: AppAccountViewModel
  
  var body: some View {
    HStack {
      if let account = viewModel.account {
        ZStack(alignment: .topTrailing) {
          AvatarView(url: account.avatar)
          if viewModel.appAccount.id == appAccounts.currentAccount.id {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.green)
              .offset(x: 5, y: -5)
          }
        }
      }
      VStack(alignment: .leading) {
        if let account = viewModel.account {
          account.displayNameWithEmojis
          Text("\(account.username)@\(viewModel.appAccount.server)")
            .font(.subheadline)
            .foregroundColor(.gray)
        }
      }
    }
    .onAppear {
      Task {
        await viewModel.fetchAccount()
      }
    }
  }
}
```


# AppAccountViewModel.swift
```swift
import SwiftUI
import Models
import Network

@MainActor
public class AppAccountViewModel: ObservableObject {
  let appAccount: AppAccount
  let client: Client
  
  @Published var account: Account?
  
  init(appAccount: AppAccount) {
    self.appAccount = appAccount
    self.client = .init(server: appAccount.server, oauthToken: appAccount.oauthToken)
  }
  
  func fetchAccount() async {
    do {
      account = try await client.get(endpoint: Accounts.verifyCredentials)
    } catch {
      print(error)
    }
  }
}
```
