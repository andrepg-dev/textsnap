import OSLog

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "TextSnap"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let capture = Logger(subsystem: subsystem, category: "capture")
}
