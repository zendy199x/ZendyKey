//
//  ZKAppDelegate.swift
//  ZendyKey
//
//  Application delegate managing lifecycle and coordination
//

import Cocoa
import SwiftUI
import Sparkle

class ZKAppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Shared Instance
    
    /// Shared instance for access from SwiftUI views
    static var shared: ZKAppDelegate?
    
    // MARK: - Properties

    private var statusBarManager: ZKStatusBarManager?
    private var eventTapManager: ZKEventTapManager?
    private var keyboardHandler: ZKKeyboardEventHandler?
    private var debugWindowController: ZKDebugWindowController?
    @available(macOS 13.0, *)
    private var settingsWindowController: ZKSettingsWindowController? {
        get { _settingsWindowController as? ZKSettingsWindowController }
        set { _settingsWindowController = newValue }
    }
    private var _settingsWindowController: NSWindowController?
    private var preferencesWindowController: ZKPreferencesWindowController?
    private var readWordHotKeyMonitor: Any?
    private var readWordGlobalHotKeyMonitor: Any?
    private var appSwitchObserver: NSObjectProtocol?
    private var mouseClickMonitor: Any?
    private var permissionAlertShown = false
    private var permissionCheckTimer: Timer?
    private var inputSourceManager: ZKInputSourceManager?
    private var switchZendyKeyHotkeyMonitor: Any?
    private var switchZendyKeyGlobalHotkeyMonitor: Any?
    private var updaterController: SPUStandardUpdaterController?
    private var onboardingWindow: NSWindow?

    // MARK: - Initialization

    override init() {
        super.init()
    }
    
    // MARK: - Public Accessors

    /// Get the keyboard handler for external access
    func getKeyboardHandler() -> ZKKeyboardEventHandler? {
        return keyboardHandler
    }

    /// Get the macro manager for external access
    func getZKMacroManager() -> ZKMacroManager? {
        if keyboardHandler == nil {
            logToDebugWindow("⚠️ ZKAppDelegate.getZKMacroManager: keyboardHandler is nil!")
            return nil
        }
        return keyboardHandler?.getZKMacroManager()
    }

    /// Log message to debug window (for external access)
    func logToDebugWindow(_ message: String) {
        debugWindowController?.logEvent(message)
    }

    /// Get the Sparkle updater for external access
    func getSparkleUpdater() -> SPUUpdater? {
        return updaterController?.updater
    }

    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Load Injection III for hot reload during development
        #if DEBUG
        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
        #endif
        
        // Set shared instance for access from SwiftUI views
        ZKAppDelegate.shared = self
        
        // Apply saved appearance mode
        AppearanceManager.shared.applyAppearance()
        
        // Create debug window first
        setupDebugWindow()
        
        debugWindowController?.logEvent("🚀 ZendyKey starting...")

        // Load and apply preferences
        let preferences = ZKSharedSettings.shared.loadPreferences()
        
        // Load custom Window Title Rules
        AppBehaviorDetector.shared.loadCustomRules()
        debugWindowController?.logEvent("  ✅ Loaded \(AppBehaviorDetector.shared.getCustomRules().count) custom Window Title Rules")
        
        // Initialize components
        setupKeyboardHandling()
        setupStatusBar()
        
        // Apply loaded preferences
        applyPreferences(preferences)

        // Check permissions
        checkAndRequestPermissions()

        // Setup global hotkey
        setupGlobalHotkey()
        
        // Setup input method and code table hotkeys
        setupInputMethodHotkey()
        setupCodeTableHotkey()
        
        // Setup read word hotkey
        setupReadWordHotkey()

        // Setup app switch observer
        setupAppSwitchObserver()
        
        // Setup mouse click monitor
        setupMouseClickMonitor()

        // Setup input source manager
        setupZKInputSourceManager()

        // Setup input source observer (auto-disable for non-Latin keyboards)
        setupInputSourceObserver()

        // Setup Sparkle auto-update
        setupSparkleUpdater()
        
        // Setup Vietnamese toggle notifications (for Settings integration)
        setupVietnameseToggleObservers()
        
        // Show onboarding on first launch
        showOnboardingIfNeeded()
        
        // Silent update check after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.silentUpdateCheck()
        }

        debugWindowController?.updateStatus("ZendyKey started successfully")
        debugWindowController?.logEvent("✅ ZendyKey started successfully")
    }
    
    private func setupVietnameseToggleObservers() {
        // Listen for toggle requests from Settings
        NotificationCenter.default.addObserver(
            forName: .toggleVietnameseFromSettings,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let enabled = notification.userInfo?["enabled"] as? Bool {
                self?.statusBarManager?.viewModel.isVietnameseEnabled = enabled
                self?.debugWindowController?.logEvent("🔄 Vietnamese mode \(enabled ? "enabled" : "disabled") from Settings")
            }
        }
        
        // Listen for state request from Settings
        NotificationCenter.default.addObserver(
            forName: .requestVietnameseState,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let isEnabled = self?.statusBarManager?.viewModel.isVietnameseEnabled ?? true
            NotificationCenter.default.post(
                name: .vietnameseModeDidChange,
                object: nil,
                userInfo: ["enabled": isEnabled]
            )
        }
        
        debugWindowController?.logEvent("  ✅ Vietnamese toggle observers setup")
    }
    
    private func showOnboardingIfNeeded() {
        if !hasCompletedOnboarding() {
            debugWindowController?.logEvent("📋 First launch - showing onboarding")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showOnboarding()
            }
        }
    }
    
    func showOnboarding() {
        // Observe onboarding completion notification (like GoNhanh pattern)
        NotificationCenter.default.addObserver(
            forName: .onboardingCompleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.debugWindowController?.logEvent("✅ Onboarding completed via notification")
            
            // Sync input method from UserDefaults.standard to ZKSharedSettings
            let inputMethod = UserDefaults.standard.integer(forKey: "ZendyKey.inputMethod")
            if inputMethod > 0 {
                ZKSharedSettings.shared.inputMethod = inputMethod
            }
            
            // Clear window reference (window already closed by OnboardingView)
            self?.onboardingWindow = nil
            
            // Open Settings window after onboarding
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.openPreferences()
            }
        }
        
        // Create onboarding window if not exists (like GoNhanh pattern)
        if onboardingWindow == nil {
            let view = ZKOnboardingView()
            let controller = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: controller)
            window.title = "Chào mừng đến với ZendyKey"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 600, height: 680))
            window.center()
            // Do NOT set window.delegate = self here - it can cause issues when closing
            window.isReleasedWhenClosed = false
            onboardingWindow = window
        }
        
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        debugWindowController?.logEvent("👋 ZendyKey terminating...")
        eventTapManager?.stop()

        // Remove read word hotkey monitors
        if let monitor = readWordHotKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = readWordGlobalHotKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Remove switch ZendyKey hotkey monitors
        if let monitor = switchZendyKeyHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = switchZendyKeyGlobalHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
        }

        // Remove app switch observer
        if let observer = appSwitchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        
        // Stop permission check timer
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    /// Handle Dock icon click - open preferences
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // No visible windows, open preferences
            openPreferences()
        }
        return true
    }
    
    // MARK: - URL Scheme Handler
    
    /// Handle URL scheme: ZendyKey://settings opens preferences
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard url.scheme == "ZendyKey" else { continue }
            
            switch url.host {
            case "settings", "preferences":
                // Open settings window
                debugWindowController?.logEvent("📲 Received URL: \(url.absoluteString) - opening settings")
                openPreferences()
            default:
                // Just activate the app
                debugWindowController?.logEvent("📲 Received URL: \(url.absoluteString)")
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    // MARK: - Setup

    private func setupDebugWindow() {
        // Check if debug mode is enabled in preferences
        let preferences = ZKSharedSettings.shared.loadPreferences()
        let shouldShowDebug = preferences.debugModeEnabled

        // Show debug window only if enabled in settings
        if shouldShowDebug {
            debugWindowController = ZKDebugWindowController()
            debugWindowController?.showWindow(nil)
            debugWindowController?.logEvent("✅ Debug window created (enabled in settings)")

            // Connect ZKDebugLogger to debug window
            ZKDebugLogger.shared.debugWindowController = debugWindowController

            // Setup read word callback
            debugWindowController?.setupReadWordCallback { [weak self] in
                self?.keyboardHandler?.engine.debugReadWordBeforeCursor()
            }
        }
    }

    private func setupKeyboardHandling() {
        debugWindowController?.logEvent("🔧 Setting up keyboard handling...")

        // Create keyboard handler
        keyboardHandler = ZKKeyboardEventHandler()
        debugWindowController?.logEvent("  ✅ Keyboard handler created")
        
        // Connect debug logging (only if logging is enabled)
        // Filter to reduce log spam
        keyboardHandler?.debugLogCallback = { [weak self] message in
            guard let self = self,
                  let debugWindow = self.debugWindowController,
                  debugWindow.isLoggingEnabled else { return }
            
            // Filter out verbose messages to reduce lag (unless verbose mode)
            if debugWindow.isVerboseLogging {
                debugWindow.logEvent(message)
            } else {
                // Always log important messages
                let shouldLog = message.contains("KEY:") ||
                               message.contains("CONSUME") ||
                               message.contains("Inject:") ||
                               message.contains("BACKSPACE") ||
                               message.contains("WORD BREAK") ||
                               message.contains("CURSOR MOVEMENT") ||
                               message.contains("===") ||
                               message.contains("DEBUG:") ||  // Read Word logs
                               message.contains("Text:") ||
                               message.contains("Word:") ||
                               message.contains("Valid:") ||
                               message.contains("Chrome") ||  // Chrome fix logs
                               message.contains("[AX]")  // Accessibility logs
                
                if shouldLog {
                    debugWindow.logEvent(message)
                }
            }
        }

        // Create event tap manager
        eventTapManager = ZKEventTapManager()
        eventTapManager?.delegate = keyboardHandler
        debugWindowController?.logEvent("  ✅ Event tap manager created, delegate set")
        
        // Connect debug logging (only if logging is enabled)
        // EventTap logs are very verbose, skip most of them
        eventTapManager?.debugLogCallback = { [weak self] message in
            guard let self = self,
                  let debugWindow = self.debugWindowController,
                  debugWindow.isLoggingEnabled else { return }
            
            // Log important EventTap messages (setup, errors, status changes, modifier key features)
            let shouldLog = message.contains("No delegate") ||
                           message.contains("disabled") ||
                           message.contains("🚀") ||  // Start
                           message.contains("✅") ||  // Success
                           message.contains("❌") ||  // Error
                           message.contains("⏹️") ||  // Stop
                           message.contains("⏸️") ||  // Pause key
                           message.contains("▶️") ||  // Resume
                           message.contains("🔄") ||  // Restore key
                           message.contains("🔤") ||  // Temp off spelling
                           message.contains("ℹ️")     // Info
            
            if shouldLog {
                debugWindow.logEvent(message)
            }
        }
        
        // Setup callbacks for pause key (hold to temporarily switch to English)
        // Use closure to capture previous state
        var previousVietnameseState: Bool = true
        eventTapManager?.onPauseKeyDown = { [weak self] in
            guard let self = self else { return }
            // Save current state before switching
            previousVietnameseState = self.statusBarManager?.viewModel.isVietnameseEnabled ?? true
            // Temporarily switch to English
            self.keyboardHandler?.setVietnamese(false)
            self.statusBarManager?.viewModel.isVietnameseEnabled = false
        }
        eventTapManager?.onPauseKeyUp = { [weak self] in
            guard let self = self else { return }
            // Restore previous state
            self.keyboardHandler?.setVietnamese(previousVietnameseState)
            self.statusBarManager?.viewModel.isVietnameseEnabled = previousVietnameseState
        }
        
        // Setup callback for restore key (press to restore original text)
        eventTapManager?.onRestoreKeyPressed = { [weak self] proxy in
            guard let self = self, let handler = self.keyboardHandler else { return false }
            return handler.performRestore(proxy: proxy)
        }
        
        // Setup callback for temp off spelling (hold to temporarily disable spell check)
        eventTapManager?.onTempOffSpellingStateChange = { [weak self] isPressed in
            guard let self = self, let handler = self.keyboardHandler else { return }
            handler.engine.vTempOffSpelling = isPressed ? 1 : 0
        }

        // Check permission BEFORE trying to start event tap
        // This prevents macOS system dialog from appearing
        guard let manager = eventTapManager else { return }

        // Check if current input source is ZKIMMain
        // If so, don't start event tap yet (will be started when switching away)
        if let currentSource = ZKInputSourceManager.getCurrentInputSource(),
           ZKInputSourceManager.isZendyKeyInputSource(currentSource) {
            debugWindowController?.logEvent("  ⏸️ Current input source is ZKIMMain - event tap will NOT start")
            debugWindowController?.logEvent("     Event tap will start automatically when switching away from ZKIMMain")
            return
        }

        if manager.checkAccessibilityPermission() {
            // Permission already granted, start event tap
            do {
                try manager.start()
                debugWindowController?.updateStatus("Event tap started - Ready to type!")
                debugWindowController?.logEvent("  ✅ Event tap started successfully!")
            } catch {
                debugWindowController?.updateStatus("ERROR: Failed to start event tap")
                debugWindowController?.logEvent("  ❌ Failed to start event tap: \(error)")
            }
        } else {
            // No permission yet - don't call start() to avoid system dialog
            debugWindowController?.updateStatus("Waiting for accessibility permission...")
            debugWindowController?.logEvent("  ⚠️ Accessibility permission not granted yet")
        }
    }
    
    private func setupStatusBar() {
        statusBarManager = ZKStatusBarManager(
            keyboardHandler: keyboardHandler,
            eventTapManager: eventTapManager
        )
        statusBarManager?.viewModel.onOpenPreferences = { [weak self] in
            self?.openPreferences()
        }
        statusBarManager?.viewModel.onOpenMacroManagement = { [weak self] in
            self?.openMacroManagement()
        }
        statusBarManager?.viewModel.onOpenZKConvertTool = { [weak self] in
            self?.openZKConvertTool()
        }
        statusBarManager?.onCheckForUpdates = { [weak self] in
            self?.checkForUpdates()
        }
        statusBarManager?.setupStatusBar()
    }
    
    // MARK: - Preferences
    
    func openPreferences() {
        if #available(macOS 13.0, *) {
            openSettings()
        } else {
            openLegacyPreferences()
        }
    }
    
    @available(macOS 13.0, *)
    func openSettings(selectedSection: SettingsSection = .general) {
        // Close existing window if section is different
        if let existingController = settingsWindowController {
            existingController.close()
            settingsWindowController = nil
        }
        
        settingsWindowController = ZKSettingsWindowController(selectedSection: selectedSection) { [weak self] preferences in
            self?.applyPreferences(preferences)
        }
        
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Convenience method to open settings with specific section
    @available(macOS 13.0, *)
    func openSettingsWithSection(_ section: SettingsSection) {
        openSettings(selectedSection: section)
    }
    
    func openLegacyPreferences(selectedTab: Int = 0) {
        // Close existing window if tab is different
        if let existingController = preferencesWindowController {
            existingController.close()
            preferencesWindowController = nil
        }
        
        preferencesWindowController = ZKPreferencesWindowController(selectedTab: selectedTab) { [weak self] preferences in
            self?.applyPreferences(preferences)
        }
        
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func openMacroManagement() {
        if #available(macOS 13.0, *) {
            openSettings(selectedSection: .macro)
        } else {
            openLegacyPreferences(selectedTab: 2) // Tab 2 = Nâng cao (has Macro section)
        }
    }
    
    func openZKConvertTool() {
        if #available(macOS 13.0, *) {
            openSettings(selectedSection: .convertTool)
        } else {
            openLegacyPreferences(selectedTab: 2) // Tab 2 = Nâng cao
        }
    }
    
    private func applyPreferences(_ preferences: Preferences) {
        // Apply basic settings
        keyboardHandler?.inputMethod = preferences.inputMethod
        keyboardHandler?.codeTable = preferences.codeTable
        keyboardHandler?.modernStyle = preferences.modernStyle
        keyboardHandler?.spellCheckEnabled = preferences.spellCheckEnabled
        keyboardHandler?.fixAutocomplete = preferences.fixAutocomplete
        
        // Apply advanced features
        keyboardHandler?.quickTelexEnabled = preferences.quickTelexEnabled
        keyboardHandler?.quickStartConsonantEnabled = preferences.quickStartConsonantEnabled
        keyboardHandler?.quickEndConsonantEnabled = preferences.quickEndConsonantEnabled
        keyboardHandler?.upperCaseFirstChar = preferences.upperCaseFirstChar
        keyboardHandler?.restoreIfWrongSpelling = preferences.restoreIfWrongSpelling
        keyboardHandler?.allowConsonantZFWJ = preferences.allowConsonantZFWJ
        keyboardHandler?.freeMarkEnabled = preferences.freeMarkEnabled
        
        // Apply macro settings
        keyboardHandler?.macroEnabled = preferences.macroEnabled
        keyboardHandler?.macroInEnglishMode = preferences.macroInEnglishMode
        keyboardHandler?.autoCapsMacro = preferences.autoCapsMacro
        
        // Apply smart switch
        keyboardHandler?.smartSwitchEnabled = preferences.smartSwitchEnabled
        
        // Apply excluded apps
        keyboardHandler?.excludedApps = preferences.excludedApps
        
        // Apply debug mode (toggle debug window)
        toggleDebugWindow(enabled: preferences.debugModeEnabled)
        
        // Update status bar manager
        statusBarManager?.viewModel.currentInputMethod = preferences.inputMethod
        statusBarManager?.viewModel.currentCodeTable = preferences.codeTable
        
        // Update hotkey display in menu
        statusBarManager?.updateHotkeyDisplay(preferences.toggleHotkey)
        
        // Update menu bar icon style
        statusBarManager?.updateMenuBarIconStyle(preferences.menuBarIconStyle)
        
        // Update Dock icon visibility
        updateDockIconVisibility(show: preferences.showDockIcon)
        
        // Update hotkey
        setupGlobalHotkey(with: preferences.toggleHotkey)
        
        // Update input method and code table hotkeys
        setupInputMethodHotkey(with: preferences.inputMethodHotkey)
        setupCodeTableHotkey(with: preferences.codeTableHotkey)
        
        // Rebuild menu to show updated hotkeys
        statusBarManager?.rebuildMenu()
        
        // Update switch ZendyKey hotkey
        setupSwitchZendyKeyHotkey(with: preferences.switchToZendyKeyHotkey)
        
        // MARK: - Configure EventTapManager for all 3 modifier key features
        
        // 1. Restore key (ESC/Option/Control) - press to restore original text
        let restoreEnabled = preferences.restoreOnEscape
        eventTapManager?.restoreKeyEnabled = restoreEnabled
        eventTapManager?.restoreKeyCode = preferences.restoreKey.rawValue
        debugWindowController?.logEvent(restoreEnabled ? "  ✅ Restore key enabled (\(preferences.restoreKey.displayName))" : "  ⏹️ Restore key disabled")
        
        // 2. Pause key (Control/Option/Cmd) - hold to temporarily switch to English
        eventTapManager?.pauseKeyEnabled = preferences.pauseKeyEnabled
        eventTapManager?.pauseKeyCode = preferences.pauseKey
        if preferences.pauseKeyEnabled {
            debugWindowController?.logEvent("  ✅ Pause key enabled (\(preferences.pauseKeyName))")
        }
        
        // 3. Temp off spelling key (Control/Option/Cmd) - hold to temporarily disable spell check
        eventTapManager?.tempOffSpellingEnabled = preferences.tempOffSpellingEnabled
        eventTapManager?.tempOffSpellingKey = preferences.tempOffSpellingKey
        if preferences.tempOffSpellingEnabled {
            let keyName: String
            switch preferences.tempOffSpellingKey {
            case 55: keyName = "Cmd"
            case 58: keyName = "Option"
            case 59: keyName = "Control"
            default: keyName = "Key(\(preferences.tempOffSpellingKey))"
            }
            debugWindowController?.logEvent("  ✅ Temp off spelling key enabled (\(keyName))")
        }
        
        // Sync to engine settings
        keyboardHandler?.engine.vEscRestoreEnabled = restoreEnabled ? 1 : 0
        keyboardHandler?.engine.vEnglishAutoRestore = preferences.autoRestoreEnglishEnabled ? 1 : 0
        keyboardHandler?.engine.vSoundOnToggle = preferences.beepOnToggle ? 1 : 0
        keyboardHandler?.engine.vSkipWShortcut = preferences.skipWShortcut ? 1 : 0
        keyboardHandler?.engine.vFreeToneEnabled = preferences.freeToneEnabled ? 1 : 0
        keyboardHandler?.engine.vPerAppModeEnabled = preferences.perAppModeEnabled ? 1 : 0
        
        if preferences.autoRestoreEnglishEnabled {
            debugWindowController?.logEvent("  ✅ Auto-restore English enabled")
        }
        if preferences.skipWShortcut {
            debugWindowController?.logEvent("  ✅ W shortcut skip enabled")
        }
        if preferences.freeToneEnabled {
            debugWindowController?.logEvent("  ✅ Free tone placement enabled")
        }
        if preferences.perAppModeEnabled {
            debugWindowController?.logEvent("  ✅ Per-app mode enabled")
        }

        debugWindowController?.logEvent("✅ Preferences applied (including advanced features)")
    }
    
    // MARK: - Debug Window Management
    
    private func toggleDebugWindow(enabled: Bool) {
        // Respect the debug mode setting
        if enabled {
            // Enable debug window
            if debugWindowController == nil {
                debugWindowController = ZKDebugWindowController()
                debugWindowController?.setupReadWordCallback { [weak self] in
                    self?.keyboardHandler?.engine.debugReadWordBeforeCursor()
                }
                debugWindowController?.logEvent("✅ Debug window enabled via settings")
            }
            debugWindowController?.showWindow(nil)
        } else {
            // Disable debug window
            if let window = debugWindowController?.window {
                window.close()
                debugWindowController = nil
            }
        }
    }
    
    // MARK: - Permissions
    
    private func checkAndRequestPermissions() {
        guard let manager = eventTapManager else { return }
        
        // Check if permission is already granted - skip everything if yes
        if manager.checkAccessibilityPermission() {
            debugWindowController?.logEvent("✅ Accessibility permission already granted - skipping prompt")
            return
        }
        
        // During first launch (onboarding), don't show the alert
        // The onboarding flow will handle permission request
        if !hasCompletedOnboarding() {
            debugWindowController?.logEvent("📋 Skipping permission alert - onboarding will handle it")
            // Just start monitoring for permission changes silently
            startPermissionMonitoring()
            return
        }
        
        // Only show permission request after onboarding is completed
        showPermissionAlert()
        // Start monitoring for permission changes
        startPermissionMonitoring()
    }
    
    private func showPermissionAlert() {
        // Only show alert once
        guard !permissionAlertShown else { return }
        permissionAlertShown = true
        
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        ZendyKey needs accessibility permission to function as a Vietnamese input method.
        
        Please grant permission in System Settings > Privacy & Security > Accessibility.
        
        After granting permission, ZendyKey will automatically start working.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Quit")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            openAccessibilityPreferences()
            // Don't show alert again after opening settings
        } else {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        
        debugWindowController?.logEvent("🔓 Opening System Settings for Accessibility permission")
    }
    
    private func startPermissionMonitoring() {
        // Check permission every 1 second - CONTINUOUSLY (never stop)
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let manager = self.eventTapManager else { return }
            
            let hasPermission = manager.checkAccessibilityPermission()
            
            if hasPermission && !manager.isRunning {
                // Permission granted but event tap not running - try to start
                self.debugWindowController?.logEvent("✅ Accessibility permission granted!")
                
                do {
                    try manager.start()
                    self.debugWindowController?.updateStatus("Event tap started - Ready to type!")
                    self.debugWindowController?.logEvent("✅ Event tap started successfully")
                } catch {
                    self.debugWindowController?.logEvent("❌ Failed to start event tap: \(error)")
                }
            } else if !hasPermission && manager.isRunning {
                // Permission revoked while event tap was running - stop it
                self.debugWindowController?.logEvent("⚠️ Accessibility permission revoked!")
                manager.stop()
                self.debugWindowController?.updateStatus("Permission revoked - Event tap stopped")
            }
        }
        
        debugWindowController?.logEvent("👀 Started continuous permission monitoring")
    }

    private func setupGlobalHotkey() {
        let preferences = ZKSharedSettings.shared.loadPreferences()
        setupGlobalHotkey(with: preferences.toggleHotkey)
    }
    
    private func setupGlobalHotkey(with hotkey: Hotkey) {
        // Configure ZKEventTapManager to handle toggle hotkey
        // This ensures the hotkey is consumed at the lowest level
        // and doesn't reach other applications
        eventTapManager?.toggleHotkey = hotkey
        eventTapManager?.onToggleHotkey = { [weak self] in
            self?.statusBarManager?.viewModel.toggleVietnamese()
            
            // Show on-screen indicator if enabled
            if ZKSharedSettings.shared.showOnScreenIndicator {
                let isVietnamese = self?.statusBarManager?.viewModel.isVietnameseEnabled ?? false
                ZKOnScreenIndicatorController.shared.show(isVietnamese: isVietnamese)
            }
            
            self?.debugWindowController?.logEvent("🔄 Toggled Vietnamese mode via hotkey (\(hotkey.displayString))")
        }

        debugWindowController?.logEvent("  ✅ Toggle hotkey configured in EventTap: \(hotkey.displayString)")
    }
    
    private func setupInputMethodHotkey() {
        let preferences = ZKSharedSettings.shared.loadPreferences()
        setupInputMethodHotkey(with: preferences.inputMethodHotkey)
    }
    
    private func setupInputMethodHotkey(with hotkey: Hotkey?) {
        eventTapManager?.inputMethodHotkey = hotkey
        eventTapManager?.onInputMethodHotkey = { [weak self] in
            guard let viewModel = self?.statusBarManager?.viewModel else { return }
            
            // Cycle to next input method in order: Telex → VNI → VIQR → Simple Telex → Simple Telex 2 → back to Telex
            let currentMethod = viewModel.currentInputMethod
            let newMethod = currentMethod.next()
            viewModel.selectInputMethod(newMethod)

            // Play beep sound if enabled
            if ZKSharedSettings.shared.beepOnToggle {
                ZKSoundManager.shared.playToggleSound(enabled: true)
            }

            // Show on-screen indicator if enabled
            if ZKSharedSettings.shared.showOnScreenIndicator {
                ZKOnScreenIndicatorController.shared.show(inputMethod: newMethod)
            }
            
            self?.debugWindowController?.logEvent("🔄 Switched input method to \(newMethod.displayName) via hotkey")
        }
        
        if let hotkey = hotkey {
            debugWindowController?.logEvent("  ✅ Input method hotkey configured: \(hotkey.displayString)")
        }
    }
    
    private func setupCodeTableHotkey() {
        let preferences = ZKSharedSettings.shared.loadPreferences()
        setupCodeTableHotkey(with: preferences.codeTableHotkey)
    }
    
    private func setupCodeTableHotkey(with hotkey: Hotkey?) {
        eventTapManager?.codeTableHotkey = hotkey
        eventTapManager?.onCodeTableHotkey = { [weak self] in
            guard let viewModel = self?.statusBarManager?.viewModel else { return }
            
            // Cycle to next code table: Unicode → TCVN3 → VNI Windows → Unicode Compound → Vietnamese Locale CP1258 → back to Unicode
            let currentTable = viewModel.currentCodeTable
            let newTable = currentTable.next()
            viewModel.selectCodeTable(newTable)

            // Play beep sound if enabled
            if ZKSharedSettings.shared.beepOnToggle {
                ZKSoundManager.shared.playToggleSound(enabled: true)
            }

            // Show on-screen indicator if enabled
            if ZKSharedSettings.shared.showOnScreenIndicator {
                ZKOnScreenIndicatorController.shared.show(codeTable: newTable)
            }
            
            self?.debugWindowController?.logEvent("🔄 Switched code table to \(newTable.displayName) via hotkey")
        }
        
        if let hotkey = hotkey {
            debugWindowController?.logEvent("  ✅ Code table hotkey configured: \(hotkey.displayString)")
        }
    }
    
    /// Public method to set hotkey recording state
    /// When true, configured hotkeys are bypassed to allow recording new hotkeys
    func setHotkeyRecordingState(_ isRecording: Bool) {
        eventTapManager?.isRecordingHotkey = isRecording
    }
    
    private func setupReadWordHotkey() {
        // Remove existing monitors
        if let monitor = readWordHotKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = readWordGlobalHotKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Shortcut: Cmd+Shift+R for "Read Word Before Cursor" (changed from Z to avoid Redo conflict)
        let keyCode: UInt16 = 0x0F // R key
        
        // Helper to check modifiers (only Cmd+Shift, no other modifiers)
        let checkModifiers: (NSEvent) -> Bool = { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            return flags.contains(.command) && flags.contains(.shift) && 
                   !flags.contains(.option) && !flags.contains(.control)
        }
        
        // Global monitor - catches hotkey in ALL apps
        readWordGlobalHotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == keyCode && checkModifiers(event) {
                DispatchQueue.main.async {
                    self?.keyboardHandler?.engine.debugReadWordBeforeCursor()
                    
                    self?.debugWindowController?.logEvent("⌨️ Read Word triggered via hotkey (Cmd+Shift+R)")
                }
            }
        }
        
        // Local monitor - catches hotkey when ZendyKey app is focused
        readWordHotKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == keyCode && checkModifiers(event) {
                DispatchQueue.main.async {
                    self?.keyboardHandler?.engine.debugReadWordBeforeCursor()
                    
                    self?.debugWindowController?.logEvent("⌨️ Read Word triggered via hotkey (Cmd+Shift+R)")
                }
                // Return nil to consume the event
                return nil
            }
            return event
        }
        
        debugWindowController?.logEvent("  ✅ Read Word hotkey: Cmd+Shift+R")
    }
    
    private func setupSwitchZendyKeyHotkey(with hotkey: Hotkey?) {
        // Remove existing monitors
        if let monitor = switchZendyKeyHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            switchZendyKeyHotkeyMonitor = nil
        }
        if let monitor = switchZendyKeyGlobalHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            switchZendyKeyGlobalHotkeyMonitor = nil
        }
        
        guard let hotkey = hotkey else {
            debugWindowController?.logEvent("  ⏹️ Switch ZendyKey hotkey disabled")
            return
        }
        
        let keyCode = hotkey.keyCode
        
        // Helper to check modifiers match exactly
        let checkModifiers: (NSEvent) -> Bool = { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            var requiredFlags: NSEvent.ModifierFlags = []
            
            if hotkey.modifiers.contains(.command) { requiredFlags.insert(.command) }
            if hotkey.modifiers.contains(.control) { requiredFlags.insert(.control) }
            if hotkey.modifiers.contains(.option) { requiredFlags.insert(.option) }
            if hotkey.modifiers.contains(.shift) { requiredFlags.insert(.shift) }
            
            // Check if flags match exactly (only required modifiers, no extras)
            let significantFlags = NSEvent.ModifierFlags([.command, .control, .option, .shift])
            let actualFlags = flags.intersection(significantFlags)
            return actualFlags == requiredFlags
        }
        
        // Global monitor - catches hotkey in ALL apps
        switchZendyKeyGlobalHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == keyCode && checkModifiers(event) {
                DispatchQueue.main.async {
                    // Check state BEFORE toggle
                    let wasZendyKey = ZKInputSourceSwitcher.shared.isZendyKeyActive
                    let action = wasZendyKey ? "ZendyKey → ABC" : "ABC → ZendyKey"

                    // Perform toggle
                    let success = ZKInputSourceSwitcher.shared.toggleZendyKey()
                    self?.debugWindowController?.logEvent("🔄 Toggle input source via hotkey (\(hotkey.displayString)) [\(action)]: \(success ? "success" : "failed")")
                }
            }
        }

        // Local monitor - catches hotkey when ZendyKey app is focused
        switchZendyKeyHotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == keyCode && checkModifiers(event) {
                DispatchQueue.main.async {
                    // Check state BEFORE toggle
                    let wasZendyKey = ZKInputSourceSwitcher.shared.isZendyKeyActive
                    let action = wasZendyKey ? "ZendyKey → ABC" : "ABC → ZendyKey"

                    // Perform toggle
                    let success = ZKInputSourceSwitcher.shared.toggleZendyKey()
                    self?.debugWindowController?.logEvent("🔄 Toggle input source via hotkey (\(hotkey.displayString)) [\(action)]: \(success ? "success" : "failed")")
                }
                // Return nil to consume the event
                return nil
            }
            return event
        }
        
        debugWindowController?.logEvent("  ✅ Switch ZendyKey hotkey: \(hotkey.displayString)")
    }

    private func setupAppSwitchObserver() {
        // Listen for app activation changes to reset engine buffer
        // This prevents buffer from previous app affecting typing in new app
        appSwitchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            // Reset keyboard handler engine when switching apps
            // Use resetForAppSwitch() which assumes typing mid-sentence to prevent
            // Forward Delete from deleting text on the right of cursor
            self.keyboardHandler?.resetForAppSwitch()

            // Handle Smart Switch - auto switch language per app
            self.handleSmartSwitch(notification: notification)

            self.debugWindowController?.logEvent("🔄 App switched - engine reset, mid-sentence mode")
        }

        debugWindowController?.logEvent("  ✅ App switch observer registered")

        // Setup overlay detector callback to restore language when overlay closes
        setupOverlayDetectorCallback()
    }

    /// Setup callback for overlay visibility changes
    private func setupOverlayDetectorCallback() {
        ZKOverlayAppDetector.shared.onOverlayVisibilityChanged = { [weak self] isVisible in
            guard let self = self else { return }

            // When overlay closes (visible → hidden), restore language for current app
            if !isVisible {
                self.debugWindowController?.logEvent("🔄 Overlay closed - restoring language for current app")
                self.restoreLanguageForCurrentApp()
            }
        }
    }

    /// Restore language for the current frontmost app from Smart Switch
    private func restoreLanguageForCurrentApp() {
        guard let handler = keyboardHandler else { return }
        guard handler.smartSwitchEnabled else { return }

        // Check if overlay detection is enabled
        let prefs = ZKSharedSettings.shared.loadPreferences()
        guard prefs.detectOverlayApps else { return }

        // Get current frontmost app
        guard let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return }

        // Get current language state
        let currentLanguage = statusBarManager?.viewModel.isVietnameseEnabled == true ? 1 : 0

        // Check if should restore language using Smart Switch logic
        let result = handler.engine.checkSmartSwitchForApp(bundleId: bundleId, currentLanguage: currentLanguage)

        // If should switch, restore the saved language
        if result.shouldSwitch {
            let newEnabled = result.newLanguage == 1
            statusBarManager?.viewModel.isVietnameseEnabled = newEnabled
            handler.setVietnamese(newEnabled)

            debugWindowController?.logEvent("✅ Restored '\(bundleId)' language → \(newEnabled ? "Vietnamese" : "English")")
        } else {
            debugWindowController?.logEvent("ℹ️ No language change needed for '\(bundleId)' (current=\(currentLanguage))")
        }
    }
    
    // MARK: - Dock Icon
    
    private func updateDockIconVisibility(show: Bool) {
        if show {
            // Show Dock icon - regular app mode
            NSApp.setActivationPolicy(.regular)
            debugWindowController?.logEvent("🖥️ Dock icon: visible")
        } else {
            // Hide Dock icon - accessory/background app mode
            NSApp.setActivationPolicy(.accessory)
            debugWindowController?.logEvent("🖥️ Dock icon: hidden")
        }
    }
    
    /// Handle Smart Switch when app changes
    private func handleSmartSwitch(notification: Notification) {
        guard let handler = keyboardHandler else { return }
        
        debugWindowController?.logEvent("🔍 Smart Switch check: enabled=\(handler.smartSwitchEnabled), vUseSmartSwitchKey=\(handler.engine.vUseSmartSwitchKey)")
        
        // Get the new active app
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }
        
        // Handle per-app code table restore (OpenKey vRememberCode feature)
        statusBarManager?.viewModel.restoreCodeTableForApp(bundleId: bundleId)
        
        guard handler.smartSwitchEnabled else { return }
        
        // Get current language from UI (StatusBar) - this is the source of truth
        let currentLanguage = statusBarManager?.viewModel.isVietnameseEnabled == true ? 1 : 0
        
        debugWindowController?.logEvent("🔍 Smart Switch: bundleId=\(bundleId), currentLanguage=\(currentLanguage)")
        
        // Check if should switch language, passing the actual current language
        let result = handler.engine.checkSmartSwitchForApp(bundleId: bundleId, currentLanguage: currentLanguage)
        
        debugWindowController?.logEvent("🔍 Smart Switch result: shouldSwitch=\(result.shouldSwitch), newLanguage=\(result.newLanguage)")
        
        if result.shouldSwitch {
            // Switch language
            let newEnabled = result.newLanguage == 1
            statusBarManager?.viewModel.isVietnameseEnabled = newEnabled
            handler.setVietnamese(newEnabled)
            
            debugWindowController?.logEvent("🔄 Smart Switch: '\(bundleId)' → \(newEnabled ? "Vietnamese" : "English")")
        } else {
            // App is new or language hasn't changed - save current language
            handler.engine.saveAppLanguage(bundleId: bundleId, language: currentLanguage)
            debugWindowController?.logEvent("📝 Smart Switch: Saved '\(bundleId)' → \(currentLanguage == 1 ? "Vietnamese" : "English")")
        }
    }
    
    private func setupMouseClickMonitor() {
        // Monitor mouse clicks to detect focus changes
        // When user clicks, they might be switching between input fields or moving cursor
        mouseClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            // Reset engine when mouse is clicked (likely focus change or cursor move)
            // Mark as cursor moved to disable autocomplete fix (avoid deleting text on right)
            self?.keyboardHandler?.resetWithCursorMoved()

            // Log detailed input detection info
            self?.logMouseClickInputDetection()
        }

        debugWindowController?.logEvent("  ✅ Mouse click monitor registered")
    }

    /// Log detailed information about the input type when mouse is clicked
    private func logMouseClickInputDetection() {
        // Get frontmost app info
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleId = app.bundleIdentifier else {
            debugWindowController?.logEvent("🖱️ Mouse click - engine reset, mid-sentence mode")
            return
        }

        let appName = app.localizedName ?? "Unknown"

        // Get focused element role from Accessibility API
        let detector = AppBehaviorDetector.shared
        let elementRole = detector.getFocusedElementRole() ?? "Unknown"
        
        // Get window title
        let windowTitle = detector.getCachedWindowTitle()

        // Get app behavior type
        let behavior = detector.detect()
        let behaviorName: String
        switch behavior {
        case .standard:
            behaviorName = "Standard"
        case .terminal:
            behaviorName = "Terminal"
        case .browserAddressBar:
            behaviorName = "Browser Address Bar"
        case .jetbrainsIDE:
            behaviorName = "JetBrains IDE"
        case .microsoftOffice:
            behaviorName = "Microsoft Office"
        case .spotlight:
            behaviorName = "Spotlight"
        case .electronApp:
            behaviorName = "Electron App"
        case .codeEditor:
            behaviorName = "Code Editor"
        }

        // Get injection method info
        let injectionInfo = detector.detectInjectionMethod()
        let injectionMethodName: String
        switch injectionInfo.method {
        case .fast: injectionMethodName = "Fast"
        case .slow: injectionMethodName = "Slow"
        case .selection: injectionMethodName = "Selection"
        case .autocomplete: injectionMethodName = "Autocomplete"
        }

        // Get current input source
        let inputSource = ZKInputSourceManager.getCurrentInputSource()
        let inputSourceName = inputSource?.displayName ?? "Unknown"
        
        // Get matched Window Title Rule (if any)
        let matchedRule = detector.findMatchingRule()
        
        // Get IMKit behavior
        let imkitBehavior = detector.detectIMKitBehavior()

        // Log everything with nice formatting
        debugWindowController?.logEvent("🖱️ Mouse click detected")
        debugWindowController?.logEvent("   App: \(appName) (\(bundleId))")
        debugWindowController?.logEvent("   Window: \(windowTitle.isEmpty ? "(no title)" : windowTitle)")
        debugWindowController?.logEvent("   Input Type: \(elementRole)")
        debugWindowController?.logEvent("   Behavior: \(behaviorName)")
        debugWindowController?.logEvent("   Injection: \(injectionMethodName) [bs:\(injectionInfo.delays.backspace)µs, wait:\(injectionInfo.delays.wait)µs, txt:\(injectionInfo.delays.text)µs]")
        debugWindowController?.logEvent("   IMKit: markedText=\(imkitBehavior.useMarkedText), issues=\(imkitBehavior.hasMarkedTextIssues), delay=\(imkitBehavior.commitDelay)µs")
        debugWindowController?.logEvent("   Input Source: \(inputSourceName)")
        
        // Log matched rule if any
        if let rule = matchedRule {
            debugWindowController?.logEvent("   ✅ Rule: \(rule.name) (pattern: \"\(rule.titlePattern)\")")
        }
        
        debugWindowController?.logEvent("   → Engine reset, mid-sentence mode")
    }

    private func setupZKInputSourceManager() {
        inputSourceManager = ZKInputSourceManager()

        // Connect debug logging
        inputSourceManager?.debugLogCallback = { [weak self] message in
            self?.debugWindowController?.logEvent(message)
        }

        // Handle input source changes
        inputSourceManager?.onInputSourceChanged = { [weak self] source, shouldEnable in
            self?.handleInputSourceChange(source: source, shouldEnable: shouldEnable)
        }

        debugWindowController?.logEvent("  ✅ Input Source Manager initialized")

        // IMPORTANT: Check current input source on startup and apply config
        if let currentSource = ZKInputSourceManager.getCurrentInputSource() {
            let shouldEnable = inputSourceManager?.isEnabled(for: currentSource.id) ?? true
            debugWindowController?.logEvent("🌐 Initial Input Source: \(currentSource.displayName)")
            debugWindowController?.logEvent("   Should enable ZendyKey: \(shouldEnable)")
            handleInputSourceChange(source: currentSource, shouldEnable: shouldEnable)
        }
    }

    /// Handle input source changes - apply enable/disable logic
    private func handleInputSourceChange(source: InputSourceInfo, shouldEnable: Bool) {
        // Check if this is ZKIMMain input source
        let isZKIMMain = ZKInputSourceManager.isZendyKeyInputSource(source)

        if isZKIMMain {
            // Switched TO ZKIMMain - suspend CGEvent tap to let IMKit handle events
            debugWindowController?.logEvent("🔑 Switched to ZKIMMain - suspending CGEvent tap")
            eventTapManager?.suspend()

            // Force enable Vietnamese mode for ZKIMMain
            self.statusBarManager?.viewModel.isVietnameseEnabled = true
            self.keyboardHandler?.setVietnamese(true)
        } else {
            // Switched AWAY from ZKIMMain
            debugWindowController?.logEvent("🔄 Switched away from ZKIMMain")

            // Check if event tap is already running
            // If not (e.g., started with ZKIMMain active), start it now
            guard let manager = eventTapManager else { return }

            // Try to start event tap if it's not running
            do {
                try manager.start()
                debugWindowController?.logEvent("  ✅ Event tap started (was not running)")
            } catch ZKEventTapManager.EventTapError.alreadyRunning {
                // Already running - just resume it
                debugWindowController?.logEvent("  ▶️ Resuming event tap")
                manager.resume()
            } catch {
                debugWindowController?.logEvent("  ❌ Failed to start event tap: \(error)")
            }

            // Get current state
            let currentlyEnabled = self.statusBarManager?.viewModel.isVietnameseEnabled ?? false

            // Auto enable/disable Vietnamese mode based on configuration
            if shouldEnable {
                // Enable Vietnamese mode
                if !currentlyEnabled {
                    self.statusBarManager?.viewModel.isVietnameseEnabled = true
                    self.keyboardHandler?.setVietnamese(true)
                    self.debugWindowController?.logEvent("✅ Input Source '\(source.displayName)' → Auto-enabled")
                }
            } else {
                // Disable Vietnamese mode
                if currentlyEnabled {
                    self.statusBarManager?.viewModel.isVietnameseEnabled = false
                    self.keyboardHandler?.setVietnamese(false)
                    self.debugWindowController?.logEvent("⏹️ Input Source '\(source.displayName)' → Auto-disabled")
                }
            }
        }
    }

    // MARK: - Sparkle Auto-Update

    private func checkForUpdates() {
        debugWindowController?.logEvent("🔍 Manually checking for updates...")
        // Activate app to bring update dialog to front
        NSApp.activate(ignoringOtherApps: true)
        updaterController?.updater.checkForUpdates()
    }
    
    /// Check for updates from SwiftUI views (activates app to bring dialog to front)
    func checkForUpdatesFromUI() {
        debugWindowController?.logEvent("🔍 [UI] Manually checking for updates...")
        
        // Must be called on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Activate app to bring update dialog to front
            NSApp.activate(ignoringOtherApps: true)
            
            // Use the same method as menu bar - updater.checkForUpdates()
            if let updater = self.updaterController?.updater {
                self.debugWindowController?.logEvent("✅ [UI] Calling updater.checkForUpdates()")
                updater.checkForUpdates()
            } else {
                self.debugWindowController?.logEvent("❌ [UI] updaterController or updater is nil!")
            }
        }
    }


    private func setupSparkleUpdater() {
        do {
            // Initialize Sparkle updater controller
            // This will automatically check for updates based on Info.plist settings:
            // - SUFeedURL: appcast feed URL
            // - SUPublicEDKey: public key for signature verification
            // - SUEnableAutomaticChecks: enable automatic update checks
            // - SUScheduledCheckInterval: check interval in seconds (86400 = 24 hours)
            updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
            
            debugWindowController?.logEvent("✅ Sparkle auto-update initialized")
            debugWindowController?.logEvent("   Feed URL: \(Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? "Not configured")")
            debugWindowController?.logEvent("   Auto-check: \(Bundle.main.object(forInfoDictionaryKey: "SUEnableAutomaticChecks") as? Bool ?? false)")
            
        } catch {
            debugWindowController?.logEvent("❌ Failed to initialize Sparkle: \(error)")
        }
    }
    
    // MARK: - Input Source Observer (Auto-disable for non-Latin keyboards)
    
    private func setupInputSourceObserver() {
        // Start input source observer
        ZKInputSourceObserver.shared.start()
        
        // Setup callbacks for "Other Language Mode" feature (OpenKey vOtherLanguage)
        // These callbacks enable saving Vietnamese mode when switching to non-Latin keyboards
        // and restoring it when switching back to Latin keyboards
        ZKInputSourceObserver.shared.getCurrentVietnameseMode = { [weak self] in
            return self?.statusBarManager?.viewModel.isVietnameseEnabled ?? false
        }
        
        ZKInputSourceObserver.shared.onRestoreVietnameseMode = { [weak self] savedMode in
            guard let self = self else { return }
            self.statusBarManager?.viewModel.setVietnameseEnabled(savedMode)
            self.keyboardHandler?.setVietnamese(savedMode)
            self.debugWindowController?.logEvent("🌍 Other Language Mode: Restored Vietnamese mode = \(savedMode)")
        }
        
        // Set callback to handle input source changes
        ZKInputSourceObserver.shared.onInputSourceChanged = { [weak self] isAllowed in
            guard let self = self else { return }
            
            // Update status bar to reflect input source allowed state
            statusBarManager?.viewModel.isInputSourceAllowed = isAllowed
            
            // Check if auto-switch is enabled in preferences
            let prefs = ZKSharedSettings.shared.loadPreferences()
            guard prefs.inputSourceAutoSwitch else { return }
            
            if isAllowed {
                // ABC/Latin keyboard: restore user's previous enabled state
                // Don't auto-enable - just allow user to use ZendyKey if they want
                debugWindowController?.logEvent("🔤 Input source allowed (Latin) - ZendyKey available")
            } else {
                // Non-Latin keyboard (Japanese/Korean/Chinese): auto-disable ZendyKey
                // This prevents ZendyKey from interfering with other input methods
                // Note: "Other Language Mode" feature will handle restoring the state when switching back
                if statusBarManager?.viewModel.isVietnameseEnabled == true {
                    statusBarManager?.viewModel.setVietnameseEnabled(false)
                    debugWindowController?.logEvent("🔤 Non-Latin input source detected - ZendyKey auto-disabled")
                }
            }
        }
        
        debugWindowController?.logEvent("✅ Input Source Observer started")
        debugWindowController?.logEvent("   Current display char: \(ZKInputSourceObserver.shared.currentDisplayChar)")
        debugWindowController?.logEvent("   Is allowed: \(ZKInputSourceObserver.shared.isAllowedInputSource)")
    }
    
    // MARK: - Silent Update Check
    
    private func silentUpdateCheck() {
        guard let updater = updaterController?.updater else {
            debugWindowController?.logEvent("⚠️ Silent update check: updater not available")
            return
        }
        
        // Update status in ViewModel
        statusBarManager?.viewModel.updateStatus = .checking
        debugWindowController?.logEvent("🔍 Silent update check started...")
        
        // Check for updates in background (silent mode)
        updater.checkForUpdatesInBackground()
        
        // Reset status after a few seconds (Sparkle handles the actual UI)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            // If still checking, set to idle (no update found silently)
            if case .checking = self?.statusBarManager?.viewModel.updateStatus {
                self?.statusBarManager?.viewModel.updateStatus = .idle
                self?.debugWindowController?.logEvent("✅ Silent update check completed")
            }
        }
    }
}

// MARK: - NSWindowDelegate

extension ZKAppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // If it's the onboarding window, allow closing but cleanup first
        if sender === onboardingWindow {
            debugWindowController?.logEvent("📋 Onboarding window closing...")
            // Clean up reference before closing
            onboardingWindow = nil
        }
        return true
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // If onboarding window is closing and onboarding not completed, handle gracefully
        if window === onboardingWindow || (onboardingWindow == nil && !hasCompletedOnboarding()) {
            debugWindowController?.logEvent("⚠️ Onboarding closed without completing")
            // Clean up safely
            onboardingWindow = nil
        }
    }
}

