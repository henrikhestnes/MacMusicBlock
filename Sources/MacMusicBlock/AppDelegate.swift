import AppKit
import ServiceManagement
import UniformTypeIdentifiers
import MacMusicBlockCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var statusLine: NSMenuItem!
    private var enabledItem: NSMenuItem!
    private var replacementMenu: NSMenu!
    private var loginItem: NSMenuItem!
    private var launchGuard = LaunchGuard()
    private var blockedCount = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        Preferences.registerDefaults()
        configureMenu()
        enableLaunchAtLoginOnFirstRun()

        let center = NSWorkspace.shared.notificationCenter
        // Will-launch catches Music before its window appears; did-launch retries if that was too early.
        for name in [NSWorkspace.willLaunchApplicationNotification, NSWorkspace.didLaunchApplicationNotification] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
                self?.handleLaunch(of: app)
            }
        }
        center.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.launchGuard.forget(pid: app.processIdentifier)
        }

        quitRunningMusic()
        refreshMenu()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusItem.button?.performClick(nil)
        return true
    }

    // MARK: Blocking

    private func handleLaunch(of app: NSRunningApplication) {
        let replacement = Preferences.replacementBundleID
        let action = launchGuard.action(bundleID: app.bundleIdentifier, pid: app.processIdentifier,
                                        enabled: Preferences.enabled, replacementBundleID: replacement,
                                        replacementRunning: isRunning(replacement))
        guard case .terminate(let newLaunch, let openReplacement) = action else { return }
        if newLaunch { blockedCount += 1 }
        terminate(app)
        if openReplacement { openReplacementApp() }
        refreshMenu()
    }

    /// Music may already be open when the app starts or is resumed.
    private func quitRunningMusic() {
        guard Preferences.enabled else { return }
        for app in NSWorkspace.shared.runningApplications where LaunchGuard.isBlocked(app.bundleIdentifier) {
            terminate(app)
        }
    }

    private func terminate(_ app: NSRunningApplication) {
        if !app.forceTerminate() { app.terminate() }
    }

    private func isRunning(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    private func replacementURL() -> URL? {
        guard let id = Preferences.replacementBundleID, LaunchGuard.isValidReplacement(id) else { return nil }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)
    }

    private func openReplacementApp() {
        guard let url = replacementURL() else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    // MARK: Menu

    private func configureMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "music.note.slash", accessibilityDescription: "MacMusicBlock")
            ?? NSImage(systemSymbolName: "speaker.slash", accessibilityDescription: "MacMusicBlock")
        let menu = NSMenu()
        menu.autoenablesItems = false
        statusLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        menu.addItem(.separator())

        enabledItem = item("Block Apple Music", #selector(toggleEnabled), in: menu)
        let replacementItem = NSMenuItem(title: "Open Instead", action: nil, keyEquivalent: "")
        replacementMenu = NSMenu()
        replacementMenu.autoenablesItems = false
        replacementItem.submenu = replacementMenu
        menu.addItem(replacementItem)
        menu.addItem(.separator())

        loginItem = item("Launch at Login", #selector(toggleLaunchAtLogin), in: menu)
        menu.addItem(withTitle: "Quit MacMusicBlock", action: #selector(quit), keyEquivalent: "q").target = self
        menu.delegate = self
        statusItem.menu = menu
    }

    private func item(_ title: String, _ action: Selector, in menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return item
    }

    func menuWillOpen(_ menu: NSMenu) { refreshMenu() }

    private func refreshMenu() {
        let status: String
        if !Preferences.enabled {
            status = "Paused"
        } else if blockedCount == 0 {
            status = "Blocking Apple Music"
        } else {
            status = "Blocked Apple Music \(blockedCount) time\(blockedCount == 1 ? "" : "s")"
        }
        statusLine.title = status
        enabledItem.state = Preferences.enabled ? .on : .off
        statusItem.button?.appearsDisabled = !Preferences.enabled
        statusItem.button?.toolTip = "MacMusicBlock · \(status)"

        replacementMenu.removeAllItems()
        let replacement = replacementURL()
        let none = item("Nothing", #selector(clearReplacement), in: replacementMenu)
        none.state = replacement == nil ? .on : .off
        if let replacement {
            let chosen = NSMenuItem(title: FileManager.default.displayName(atPath: replacement.path), action: nil, keyEquivalent: "")
            chosen.state = .on
            let icon = NSWorkspace.shared.icon(forFile: replacement.path)
            icon.size = NSSize(width: 16, height: 16)
            chosen.image = icon
            replacementMenu.addItem(chosen)
        }
        replacementMenu.addItem(.separator())
        _ = item("Choose App…", #selector(chooseReplacement), in: replacementMenu)

        let login = SMAppService.mainApp.status
        loginItem.state = login == .enabled ? .on : login == .requiresApproval ? .mixed : .off
    }

    @objc private func toggleEnabled() {
        Preferences.enabled.toggle()
        quitRunningMusic()
        refreshMenu()
    }

    @objc private func clearReplacement() {
        Preferences.replacementBundleID = nil
        refreshMenu()
    }

    @objc private func chooseReplacement() {
        let panel = NSOpenPanel()
        panel.title = "Choose an app to open instead of Apple Music"
        panel.prompt = "Choose"
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let bundleID = Bundle(url: url)?.bundleIdentifier
        guard LaunchGuard.isValidReplacement(bundleID) else {
            showAlert("\(FileManager.default.displayName(atPath: url.path)) can't be used",
                      LaunchGuard.isBlocked(bundleID) ? "MacMusicBlock blocks that app." : "The app has no bundle identifier.")
            return
        }
        Preferences.replacementBundleID = bundleID
        refreshMenu()
    }

    /// Launch at Login defaults to on, but only once, so turning it off in the menu sticks.
    private func enableLaunchAtLoginOnFirstRun() {
        let key = "launchAtLoginConfigured"
        // Skip `swift run` binaries and translocated copies, whose paths would not survive a restart.
        let path = Bundle.main.bundlePath
        guard !UserDefaults.standard.bool(forKey: key), path.hasSuffix(".app"), !path.contains("/AppTranslocation/") else { return }
        if SMAppService.mainApp.status == .notRegistered, (try? SMAppService.mainApp.register()) == nil { return }
        UserDefaults.standard.set(true, forKey: key)
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            showAlert("Launch at Login could not be changed", error.localizedDescription)
        }
        refreshMenu()
    }

    private func showAlert(_ message: String, _ information: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = information
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
