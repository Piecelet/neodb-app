import Foundation
import OSLog

/// A unified logging system for the NeoDB app
extension Logger {
    /// Using bundle identifier as subsystem for unique identification
    private static var subsystem = Bundle.main.bundleIdentifier!

    // MARK: - App Lifecycle
    /// Logs related to app lifecycle events
    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    
    // MARK: - Networking
    /// Logs related to network requests and responses
    static let network = Logger(subsystem: subsystem, category: "network")
    
    // MARK: - Data
    /// Logs related to data persistence and caching
    static let data = Logger(subsystem: subsystem, category: "data")
    
    // MARK: - Authentication
    /// Logs related to user authentication
    static let auth = Logger(subsystem: subsystem, category: "auth")
    
    // MARK: - View Lifecycle
    /// Logs related to view lifecycle events
    static let view = Logger(subsystem: subsystem, category: "view")
    
    // MARK: - User Actions
    /// Logs related to user interactions
    static let userAction = Logger(subsystem: subsystem, category: "userAction")
    
    // MARK: - Performance
    /// Logs related to performance metrics
    static let performance = Logger(subsystem: subsystem, category: "performance")
}

// MARK: - Convenience Methods
extension Logger {
    /// Log a message with the debug level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        self.debug("[\(filename):\(line)] \(function) - \(message)")
    }
    
    /// Log a message with the info level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        self.info("[\(filename):\(line)] \(function) - \(message)")
    }
    
    /// Log a message with the error level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        self.error("[\(filename):\(line)] \(function) - \(message)")
    }
    
    /// Log a message with the warning level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        self.warning("[\(filename):\(line)] \(function) - \(message)")
    }
} 