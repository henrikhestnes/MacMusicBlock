import Foundation

enum Preferences {
    private static let defaults = UserDefaults.standard

    static func registerDefaults() {
        defaults.register(defaults: ["enabled": true])
    }

    /// Whether Apple Music is blocked.
    static var enabled: Bool {
        get { defaults.bool(forKey: "enabled") }
        set { defaults.set(newValue, forKey: "enabled") }
    }

    /// Bundle identifier of an app to open in place of Apple Music, or nil for none.
    static var replacementBundleID: String? {
        get { defaults.string(forKey: "replacementBundleID") }
        set { defaults.set(newValue, forKey: "replacementBundleID") }
    }
}
