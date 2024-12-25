import Foundation

public class ServerConfiguration {
    public static let defaultServer = "neodb.social"
    
    @Published public private(set) var currentServer: String
    
    public init(server: String = defaultServer) {
        self.currentServer = server
    }
    
    public var serverURL: URL? {
        URL(string: "https://\(currentServer)")
    }
    
    public func updateServer(_ server: String) {
        currentServer = server
    }
    
    public func resetToDefault() {
        currentServer = Self.defaultServer
    }
} 