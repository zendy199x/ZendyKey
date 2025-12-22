//
//  main.swift
//  ZKIMMain
//
//  Input Method Kit entry point for ZendyKey Vietnamese
//  This runs as a background service providing native Vietnamese input
//

import Cocoa
import InputMethodKit

// MARK: - Notification Names (shared with ZendyKey app)

extension Notification.Name {
    /// Posted when settings change (distributed, cross-app)
    static let ZendyKeySettingsDidChange = Notification.Name("ZendyKey.settingsDidChange")
}

// MARK: - App Delegate

class ZKIMMainZKAppDelegate: NSObject, NSApplicationDelegate {
    
    /// IMK Server instance
    var server: IMKServer!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create IMK server
        // The connection name must match InputMethodConnectionName in Info.plist
        server = IMKServer(
            name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String ?? "ZKIMMain_Connection",
            bundleIdentifier: Bundle.main.bundleIdentifier!
        )
        
        NSLog("ZKIMMain: Input Method server started")
        NSLog("ZKIMMain: Bundle ID = \(Bundle.main.bundleIdentifier ?? "unknown")")
        
        // Listen for settings changes from main ZendyKey app
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleSettingsChanged),
            name: .ZendyKeySettingsDidChange,
            object: nil
        )
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSLog("ZKIMMain: Input Method server stopping")
    }
    
    @objc private func handleSettingsChanged(_ notification: Notification) {
        NSLog("ZKIMMain: Settings changed, reloading...")
        // Settings will be reloaded by ZKIMMainController on next input
    }
}

// MARK: - Main Entry Point

// Create and run the application
let app = NSApplication.shared
let delegate = ZKIMMainZKAppDelegate()
app.delegate = delegate

// Run the app (this blocks until the app terminates)
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
