//
//  ZKInputMethodUpdateManager.swift
//  ZendyKey
//
//  Manages automatic updates for ZendyKeyIM (Input Method Extension)
//  Updates ZendyKeyIM by installing the bundled version from ZendyKey.app/Contents/Resources/
//

import Foundation
import AppKit

/// Manager for ZendyKeyIM auto-update functionality
class ZKInputMethodUpdateManager {
    
    // MARK: - Singleton
    
    static let shared = ZKInputMethodUpdateManager()
    
    // MARK: - Properties
    
    /// Callback for logging debug messages
    var debugLogCallback: ((String) -> Void)?
    
    /// Path to installed ZendyKeyIM
    private let installedZendyKeyIMPath = NSHomeDirectory() + "/Library/Input Methods/ZendyKeyIM.app"
    
    /// Path to bundled ZendyKeyIM in ZendyKey.app
    private var bundledZendyKeyIMPath: String? {
        return Bundle.main.resourcePath.map { $0 + "/ZendyKeyIM.app" }
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Version Checking
    
    /// Check if ZendyKeyIM needs update
    /// - Returns: True if bundled version is newer than installed version
    func needsUpdate() -> Bool {
        guard let bundledPath = bundledZendyKeyIMPath,
              FileManager.default.fileExists(atPath: bundledPath) else {
            logDebug("ZendyKeyIM: No bundled version found in ZendyKey.app/Contents/Resources/")
            return false
        }
        
        // Check if ZendyKeyIM is installed
        guard FileManager.default.fileExists(atPath: installedZendyKeyIMPath) else {
            logDebug("ZendyKeyIM: Not installed yet, will install bundled version")
            return true
        }
        
        // Compare versions
        let installedVersion = getVersion(at: installedZendyKeyIMPath)
        let bundledVersion = getVersion(at: bundledPath)
        
        logDebug("ZendyKeyIM Version Check:")
        logDebug("   Installed: \(installedVersion ?? "unknown")")
        logDebug("   Bundled:   \(bundledVersion ?? "unknown")")
        
        guard let installed = installedVersion,
              let bundled = bundledVersion else {
            logDebug("ZendyKeyIM: Could not determine versions")
            return false
        }
        
        // Compare version strings
        let needsUpdate = compareVersions(bundled, installed) == .orderedDescending
        
        if needsUpdate {
            logDebug("ZendyKeyIM: Update available (\(installed) → \(bundled))")
        } else {
            logDebug("ZendyKeyIM: Up to date (\(installed))")
        }
        
        return needsUpdate
    }
    
    /// Get version from ZendyKeyIM.app bundle
    private func getVersion(at path: String) -> String? {
        let infoPlistPath = path + "/Contents/Info.plist"
        
        guard let plistData = FileManager.default.contents(atPath: infoPlistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }
        
        // Get version and build number
        let version = plist["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = plist["CFBundleVersion"] as? String ?? "0"
        
        return "\(version).\(build)"
    }
    
    /// Compare two version strings (e.g., "1.2.17.20251229")
    /// - Returns: ComparisonResult (.orderedAscending, .orderedSame, .orderedDescending)
    private func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(v1Components.count, v2Components.count)
        
        for i in 0..<maxLength {
            let v1 = i < v1Components.count ? v1Components[i] : 0
            let v2 = i < v2Components.count ? v2Components[i] : 0
            
            if v1 < v2 {
                return .orderedAscending
            } else if v1 > v2 {
                return .orderedDescending
            }
        }
        
        return .orderedSame
    }
    
    // MARK: - Installation
    
    /// Install bundled ZendyKeyIM to ~/Library/Input Methods/
    /// - Parameter showNotification: Whether to show user notification after installation
    /// - Returns: True if installation succeeded
    @discardableResult
    func installBundledZendyKeyIM(showNotification: Bool = true) -> Bool {
        guard let bundledPath = bundledZendyKeyIMPath,
              FileManager.default.fileExists(atPath: bundledPath) else {
            logDebug("ZendyKeyIM: Cannot install - bundled version not found")
            return false
        }
        
        // Log version info if available
        let bundledVersion = getVersion(at: bundledPath)
        let installedVersion = FileManager.default.fileExists(atPath: installedZendyKeyIMPath) 
            ? getVersion(at: installedZendyKeyIMPath) 
            : nil
        
        if let installed = installedVersion, let bundled = bundledVersion {
            logDebug("ZendyKeyIM: Installing bundled version (\(installed) → \(bundled))...")
        } else {
            logDebug("ZendyKeyIM: Installing bundled version...")
        }
        
        // Kill running ZendyKeyIM process if exists
        killZendyKeyIMProcess()
        
        // Wait a bit for process to fully terminate
        Thread.sleep(forTimeInterval: 0.5)
        
        // Create Input Methods directory if needed
        let inputMethodsDir = NSHomeDirectory() + "/Library/Input Methods"
        do {
            try FileManager.default.createDirectory(atPath: inputMethodsDir, withIntermediateDirectories: true)
        } catch {
            logDebug("ZendyKeyIM: Failed to create Input Methods directory: \(error)")
            return false
        }
        
        // Remove old version
        if FileManager.default.fileExists(atPath: installedZendyKeyIMPath) {
            do {
                try FileManager.default.removeItem(atPath: installedZendyKeyIMPath)
                logDebug("Removed old version")
            } catch {
                logDebug("ZendyKeyIM: Failed to remove old version: \(error)")
                // Continue anyway, copyItem might overwrite
            }
        }
        
        // Copy new version
        do {
            try FileManager.default.copyItem(atPath: bundledPath, toPath: installedZendyKeyIMPath)
            logDebug("Copied new version")
        } catch {
            logDebug("ZendyKeyIM: Failed to copy new version: \(error)")
            return false
        }
        
        // Verify installation
        guard FileManager.default.fileExists(atPath: installedZendyKeyIMPath) else {
            logDebug("ZendyKeyIM: Installation verification failed")
            return false
        }
        
        let finalVersion = getVersion(at: installedZendyKeyIMPath)
        logDebug("ZendyKeyIM: Installed successfully (v\(finalVersion ?? "unknown"))")
        
        // Show notification to user
        if showNotification {
            showUpdateNotification(version: finalVersion ?? "unknown")
        }
        
        return true
    }
    
    /// Kill running ZendyKeyIM process
    private func killZendyKeyIMProcess() {
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["ZendyKeyIM"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                logDebug("Killed running ZendyKeyIM process")
            }
        } catch {
            // Process might not be running, that's okay
            logDebug("No running ZendyKeyIM process found")
        }
    }
    
    /// Show notification to user about ZendyKeyIM update
    private func showUpdateNotification(version: String) {
        let notification = NSUserNotification()
        notification.title = "ZendyKeyIM đã được cập nhật"
        notification.informativeText = "Phiên bản \(version) đã được cài đặt.\n\nVui lòng chuyển sang input method khác rồi quay lại ZendyKey để áp dụng."
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
        
        logDebug("ZendyKeyIM: Update notification sent to user")
    }
    
    // MARK: - Auto-Update Check
    
    /// Check and install ZendyKeyIM update if available
    /// Called automatically when ZendyKey app updates
    func checkAndInstallUpdate() {
        logDebug("ZendyKeyIM: Checking for updates...")
        
        if needsUpdate() {
            installBundledZendyKeyIM(showNotification: true)
        } else {
            logDebug("ZendyKeyIM: Already up to date")
        }
    }
    
    // MARK: - Debug Logging
    
    private func logDebug(_ message: String) {
        // Only use DebugLogger (which writes to file), debugWindowController will read from file
        sharedLogInfo(message)
    }
}
