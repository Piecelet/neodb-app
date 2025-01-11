import Foundation
import OSLog

@MainActor
class InstanceManager: ObservableObject {
    private let logger = Logger.networkAuth
    
    @Published var currentInstance: String {
        didSet {
            let lowercaseInstance = self.currentInstance.lowercased()
            if lowercaseInstance != self.currentInstance {
                self.currentInstance = lowercaseInstance
                return
            }
            // Save the current instance
            UserDefaults.standard.set(self.currentInstance, forKey: "neodb.currentInstance")
            logger.debug("Switched to instance: \(self.currentInstance)")
        }
    }
    
    private var baseURL: String { "https://\(self.currentInstance)" }
    
    init(instance: String? = nil) {
        // Load last used instance or use default, ensure it's lowercase
        self.currentInstance = (instance ?? UserDefaults.standard.string(forKey: "neodb.currentInstance") ?? "neodb.social").lowercased()
        logger.debug("Initialized with instance: \(self.currentInstance)")
    }
    
    func validateInstance(_ instance: String) -> Bool {
        let lowercaseInstance = instance.lowercased()
        // Basic validation: ensure it's a valid hostname
        let hostnameRegex = "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$"
        let hostnamePredicate = NSPredicate(format: "SELF MATCHES %@", hostnameRegex)
        return hostnamePredicate.evaluate(with: lowercaseInstance)
    }
    
    func switchInstance(_ newInstance: String) throws {
        let lowercaseInstance = newInstance.lowercased()
        guard validateInstance(lowercaseInstance) else {
            throw AuthError.invalidInstance
        }
        
        logger.debug("Switching from instance \(self.currentInstance) to \(lowercaseInstance)")
        currentInstance = lowercaseInstance
    }
    
    func getBaseURL() -> String {
        return baseURL
    }
} 