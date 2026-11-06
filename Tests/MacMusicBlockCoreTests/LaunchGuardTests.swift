import XCTest
@testable import MacMusicBlockCore

final class LaunchGuardTests: XCTestCase {
    func testBlocksMusicAndITunesOnly() {
        XCTAssertTrue(LaunchGuard.isBlocked("com.apple.Music"))
        XCTAssertTrue(LaunchGuard.isBlocked("com.apple.iTunes"))
        XCTAssertFalse(LaunchGuard.isBlocked("com.spotify.client"))
        XCTAssertFalse(LaunchGuard.isBlocked("com.apple.music")) // Bundle IDs are case-sensitive.
        XCTAssertFalse(LaunchGuard.isBlocked(nil))
    }

    func testOtherAppsAreIgnored() {
        var launchGuard = LaunchGuard()
        XCTAssertEqual(launchGuard.action(bundleID: "com.apple.Safari", pid: 1, enabled: true,
                                          replacementBundleID: nil, replacementRunning: false), .ignore)
        XCTAssertEqual(launchGuard.action(bundleID: nil, pid: 2, enabled: true,
                                          replacementBundleID: nil, replacementRunning: false), .ignore)
    }

    func testPausedGuardIgnoresMusic() {
        var launchGuard = LaunchGuard()
        XCTAssertEqual(launchGuard.action(bundleID: "com.apple.Music", pid: 1, enabled: false,
                                          replacementBundleID: "com.spotify.client", replacementRunning: false), .ignore)
    }

    func testMusicIsTerminatedWithoutReplacement() {
        var launchGuard = LaunchGuard()
        XCTAssertEqual(launchGuard.action(bundleID: "com.apple.Music", pid: 1, enabled: true,
                                          replacementBundleID: nil, replacementRunning: false),
                       .terminate(newLaunch: true, openReplacement: false))
    }

    func testReplacementOpensOncePerLaunchButTerminationRepeats() {
        var launchGuard = LaunchGuard()
        XCTAssertEqual(launchGuard.action(bundleID: "com.apple.Music", pid: 7, enabled: true,
                                          replacementBundleID: "com.spotify.client", replacementRunning: false),
                       .terminate(newLaunch: true, openReplacement: true))
        // The did-launch notification for the same process.
        XCTAssertEqual(launchGuard.action(bundleID: "com.apple.Music", pid: 7, enabled: true,
                                          replacementBundleID: "com.spotify.client", replacementRunning: false),
                       .terminate(newLaunch: false, openReplacement: false))
        // A new launch opens it again.
        XCTAssertEqual(launchGuard.action(bundleID: "com.apple.Music", pid: 8, enabled: true,
                                          replacementBundleID: "com.spotify.client", replacementRunning: false),
                       .terminate(newLaunch: true, openReplacement: true))
    }

    func testForgottenPidIsHandledAsANewLaunch() {
        var launchGuard = LaunchGuard()
        _ = launchGuard.action(bundleID: "com.apple.Music", pid: 7, enabled: true,
                               replacementBundleID: "com.spotify.client", replacementRunning: false)
        launchGuard.forget(pid: 7)
        XCTAssertEqual(launchGuard.action(bundleID: "com.apple.Music", pid: 7, enabled: true,
                                          replacementBundleID: "com.spotify.client", replacementRunning: false),
                       .terminate(newLaunch: true, openReplacement: true))
    }

    func testRunningReplacementIsNotOpenedAgain() {
        var launchGuard = LaunchGuard()
        XCTAssertEqual(launchGuard.action(bundleID: "com.apple.Music", pid: 1, enabled: true,
                                          replacementBundleID: "com.spotify.client", replacementRunning: true),
                       .terminate(newLaunch: true, openReplacement: false))
    }

    func testBlockedAppIsNeverAReplacement() {
        XCTAssertFalse(LaunchGuard.isValidReplacement("com.apple.Music"))
        XCTAssertFalse(LaunchGuard.isValidReplacement("com.apple.iTunes"))
        XCTAssertFalse(LaunchGuard.isValidReplacement(""))
        XCTAssertFalse(LaunchGuard.isValidReplacement(nil))
        XCTAssertTrue(LaunchGuard.isValidReplacement("com.spotify.client"))
        var launchGuard = LaunchGuard()
        XCTAssertEqual(launchGuard.action(bundleID: "com.apple.Music", pid: 1, enabled: true,
                                          replacementBundleID: "com.apple.Music", replacementRunning: false),
                       .terminate(newLaunch: true, openReplacement: false))
    }
}
