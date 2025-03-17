import Foundation
import OSLog

/// A unified logging system for the NeoDB app
extension Logger {
    /// Using bundle identifier as subsystem for unique identification
    private static var subsystem = Bundle.main.bundleIdentifier!

    // MARK: - App Lifecycle
    /// Logs related to app lifecycle events
    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    static let app = Logger(subsystem: subsystem, category: "app")

    // MARK: - Networking
    /// Logs related to network requests and responses
    static let network = Logger(subsystem: subsystem, category: "network")
    static let networkStream = Logger(
        subsystem: subsystem, category: "network.stream")
    static let networkRequest = Logger(
        subsystem: subsystem, category: "network.request")
    static let networkResponse = Logger(
        subsystem: subsystem, category: "network.response")

    static let networkAuth = Logger(
        subsystem: subsystem, category: "network.auth")
    static let networkTimeline = Logger(
        subsystem: subsystem, category: "network.timeline")
    static let networkItem = Logger(
        subsystem: subsystem, category: "network.item")
    static let networkShelf = Logger(
        subsystem: subsystem, category: "network.shelf")
    static let networkUser = Logger(
        subsystem: subsystem, category: "network.user")

    enum client {
        static let joinMastodon = Logger(
            subsystem: subsystem, category: "network.joinMastodon")
        static let instanceSocial = Logger(
            subsystem: subsystem, category: "network.instanceSocial")
    }

    // MARK: - Data
    /// Logs related to data persistence and caching
    static let data = Logger(subsystem: subsystem, category: "data")

    // MARK: - Cache
    static let cache = Logger(subsystem: subsystem, category: "cache")

    // MARK: - Authentication
    /// Logs related to user authentication
    static let auth = Logger(subsystem: subsystem, category: "auth")

    // MARK: - View Lifecycle
    /// Logs related to view lifecycle events
    static let view = Logger(subsystem: subsystem, category: "view")

    // MARK: - Navigation
    /// Logs related to navigation and routing
    static let router = Logger(subsystem: subsystem, category: "router")

    // MARK: - Shared Services

    enum services {
        enum url {
            static let urlHandler = Logger(
                subsystem: subsystem, category: "services.url.urlHandler")
            static let neodbURL = Logger(
                subsystem: subsystem, category: "services.url.neodbURL")
            static let urlUtilities = Logger(
                subsystem: subsystem, category: "services.url.urlUtilities")
        }

        enum telemetry {
        static let telemetry = Logger(subsystem: subsystem, category: "services.telemetry")
            static let auth = Logger(subsystem: subsystem, category: "services.telemetry.auth")
        }
    }

    // MARK: - Views
    /// Logs related to specific views
    static let home = Logger(subsystem: subsystem, category: "view.home")
    static let htmlContent = Logger(subsystem: subsystem, category: "view.html")

    enum views {
        static let contentView = Logger(subsystem: subsystem, category: "view.contentView")

        static let login = Logger(subsystem: subsystem, category: "view.login")
        static let profile = Logger(
            subsystem: subsystem, category: "view.profile")
        static let settings = Logger(
            subsystem: subsystem, category: "view.settings")
        static let purchase = Logger(
            subsystem: subsystem, category: "view.purchase")
        static let library = Logger(
            subsystem: subsystem, category: "view.library")
        static let item = Logger(subsystem: subsystem, category: "view.item")
        static let itemActions = Logger(
            subsystem: subsystem, category: "view.itemActions")
        enum mark {
            static let mark = Logger(subsystem: subsystem, category: "view.mark")
            static let starRating = Logger(subsystem: subsystem, category: "view.mark.starRating")
        }

        enum discover {
            static let gallery = Logger(subsystem: subsystem, category: "view.discover.gallery")
            static let search = Logger(subsystem: subsystem, category: "view.discover.search")
            static let searchURL = Logger(subsystem: subsystem, category: "view.discover.searchURL")
        }

        static let timelines = Logger(
            subsystem: subsystem, category: "view.timelines")
        enum status {
            static let status = Logger(
                subsystem: subsystem, category: "view.status")
            static let item = Logger(
                subsystem: subsystem, category: "view.status.item")
        }
        
        static let developer = Logger(
            subsystem: subsystem, category: "view.developer")
        static let store = Logger(
            subsystem: subsystem, category: "view.store")
        static let troubleshooting = Logger(
            subsystem: subsystem, category: "view.troubleshooting")
    }

    // MARK: - User Actions
    /// Logs related to user interactions
    static let userAction = Logger(subsystem: subsystem, category: "userAction")

    // MARK: - Performance
    /// Logs related to performance metrics
    static let performance = Logger(
        subsystem: subsystem, category: "performance")

    // MARK: - Managers
    enum managers {
        static let store = Logger(
            subsystem: subsystem, category: "manager.store")
        static let account = Logger(
            subsystem: subsystem, category: "manager.account")
        static let client = Logger(
            subsystem: subsystem, category: "manager.client")
        static let accountsManager = Logger(
            subsystem: subsystem, category: "manager.accountsManager")
    }

    // MARK: - Data Controllers
    enum dataControllers {
        static let markDataController = Logger(
            subsystem: subsystem, category: "dataControllers.markDataController")
        static let statusDataController = Logger(
            subsystem: subsystem, category: "dataControllers.statusDataController")
    }
}

// MARK: - Convenience Methods
extension Logger {
    private func formatMessage(
        _ message: String, file: String = #file, function: String = #function,
        line: Int = #line
    ) -> String {
        #if DEBUG
            let filename = (file as NSString).lastPathComponent
            return "[\(filename):\(line)] \(function) - \(message)"
        #else
            return message
        #endif
    }

    /// Log a message with the debug level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func debug(
        _ message: String, file: String = #file, function: String = #function,
        line: Int = #line
    ) {
        log(
            level: .debug,
            "\(formatMessage(message, file: file, function: function, line: line))"
        )
    }

    /// Log a message with the info level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func info(
        _ message: String, file: String = #file, function: String = #function,
        line: Int = #line
    ) {
        log(
            level: .info,
            "\(formatMessage(message, file: file, function: function, line: line))"
        )
    }

    /// Log a message with the error level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func error(
        _ message: String, file: String = #file, function: String = #function,
        line: Int = #line
    ) {
        log(
            level: .error,
            "\(formatMessage(message, file: file, function: function, line: line))"
        )
    }

    /// Log a message with the warning level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func warning(
        _ message: String, file: String = #file, function: String = #function,
        line: Int = #line
    ) {
        log(
            level: .default,
            "\(formatMessage(message, file: file, function: function, line: line))"
        )
    }
}
