import Foundation

/// Decides what to do when an app launches. AppKit-free so the policy can be unit tested.
public struct LaunchGuard {
    /// Apple Music, and iTunes on systems or installs that still have it.
    public static let blockedBundleIDs: Set<String> = ["com.apple.Music", "com.apple.iTunes"]

    public enum Action: Equatable {
        case ignore
        /// `newLaunch` is true the first time a process is seen.
        case terminate(newLaunch: Bool, openReplacement: Bool)
    }

    /// Processes already handled. A launch posts both a will-launch and a did-launch notification;
    /// both terminate (the first attempt can fail while the app is still starting), but only the
    /// first may open the replacement app.
    private var handled: Set<Int32> = []

    public init() {}

    public static func isBlocked(_ bundleID: String?) -> Bool {
        bundleID.map(blockedBundleIDs.contains) ?? false
    }

    /// A replacement must be a real app other than the ones being blocked.
    public static func isValidReplacement(_ bundleID: String?) -> Bool {
        guard let bundleID, !bundleID.isEmpty else { return false }
        return !isBlocked(bundleID)
    }

    public mutating func action(bundleID: String?, pid: Int32, enabled: Bool,
                                replacementBundleID: String?, replacementRunning: Bool) -> Action {
        guard enabled, Self.isBlocked(bundleID) else { return .ignore }
        let firstSighting = handled.insert(pid).inserted
        let open = firstSighting && Self.isValidReplacement(replacementBundleID) && !replacementRunning
        return .terminate(newLaunch: firstSighting, openReplacement: open)
    }

    /// Call when a process exits, so a later process that reuses its pid is handled again.
    public mutating func forget(pid: Int32) {
        handled.remove(pid)
    }
}
