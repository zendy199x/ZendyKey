//
//  ZKPerAppModeManager.swift
//  ZendyKey
//
//  Manages per-application language mode preferences
//  Remembers whether user was in Vietnamese or English mode for each app
//

import AppKit

class ZKPerAppModeManager {
    static let shared = ZKPerAppModeManager()
    
    private let storageKey = "perAppLanguageModes"
    
    // Cache of app modes: bundleId -> isVietnamese
    private var appModes: [String: Bool] = [:]
    
    private init() {
        loadFromDefaults()
    }
    
    // MARK: - Public API
    
    /// Get the saved language mode for an app
    /// Returns nil if no preference saved (use default)
    func getLanguageMode(forBundleId bundleId: String) -> Bool? {
        return appModes[bundleId]
    }
    
    /// Save the language mode for an app
    func setLanguageMode(forBundleId bundleId: String, isVietnamese: Bool) {
        appModes[bundleId] = isVietnamese
        saveToDefaults()
    }
    
    /// Get mode for current frontmost app
    func getLanguageModeForFrontmostApp() -> Bool? {
        guard let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return nil
        }
        return getLanguageMode(forBundleId: bundleId)
    }
    
    /// Save mode for current frontmost app
    func setLanguageModeForFrontmostApp(isVietnamese: Bool) {
        guard let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return
        }
        setLanguageMode(forBundleId: bundleId, isVietnamese: isVietnamese)
    }
    
    /// Clear all saved modes
    func clearAllModes() {
        appModes.removeAll()
        saveToDefaults()
    }
    
    /// Get all saved app modes
    func getAllModes() -> [String: Bool] {
        return appModes
    }
    
    // MARK: - Persistence
    
    private func loadFromDefaults() {
        if let data = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Bool] {
            appModes = data
        }
    }
    
    private func saveToDefaults() {
        UserDefaults.standard.set(appModes, forKey: storageKey)
    }
}
