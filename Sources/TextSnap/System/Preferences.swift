import Foundation
import TextSnapCore

@MainActor
final class Preferences {
    private enum Key {
        static let outputFormat = "outputFormat"
        static let hasConfiguredLoginItem = "hasConfiguredLoginItem"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var outputFormat: OutputFormat {
        get { defaults.string(forKey: Key.outputFormat).flatMap(OutputFormat.init(rawValue:)) ?? .markdown }
        set { defaults.set(newValue.rawValue, forKey: Key.outputFormat) }
    }

    /// Launch at login is turned on once, on first run; afterwards the user's choice wins.
    var hasConfiguredLoginItem: Bool {
        get { defaults.bool(forKey: Key.hasConfiguredLoginItem) }
        set { defaults.set(newValue, forKey: Key.hasConfiguredLoginItem) }
    }
}
