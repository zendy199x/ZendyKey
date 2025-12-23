//
//  ZKPerAppCodeTableManager.swift
//  ZendyKey
//
//  Manages per-application code table preferences
//  Remembers which code table (Unicode, TCVN3, VNI, etc.) was used in each app
//

import AppKit

class ZKPerAppCodeTableManager {
    static let shared = ZKPerAppCodeTableManager()
    
    private let storageKey = "perAppCodeTables"
    
    // Cache of app code tables: bundleId -> CodeTable.rawValue
    private var appCodeTables: [String: Int] = [:]
    
    private init() {
        loadFromDefaults()
    }
    
    // MARK: - Public API
    
    /// Get the saved code table for an app
    /// Returns nil if no preference saved (use default)
    func getCodeTable(forBundleId bundleId: String) -> Int? {
        return appCodeTables[bundleId]
    }
    
    /// Save the code table for an app
    func setCodeTable(forBundleId bundleId: String, codeTable: Int) {
        appCodeTables[bundleId] = codeTable
        saveToDefaults()
    }
    
    /// Get code table for current frontmost app
    func getCodeTableForFrontmostApp() -> Int? {
        guard let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return nil
        }
        return getCodeTable(forBundleId: bundleId)
    }
    
    /// Save code table for current frontmost app
    func setCodeTableForFrontmostApp(codeTable: Int) {
        guard let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return
        }
        setCodeTable(forBundleId: bundleId, codeTable: codeTable)
    }
    
    /// Clear all saved code tables
    func clearAllCodeTables() {
        appCodeTables.removeAll()
        saveToDefaults()
    }
    
    /// Get all saved app code tables
    func getAllCodeTables() -> [String: Int] {
        return appCodeTables
    }
    
    // MARK: - Persistence
    
    private func loadFromDefaults() {
        if let data = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Int] {
            appCodeTables = data
        }
    }
    
    private func saveToDefaults() {
        UserDefaults.standard.set(appCodeTables, forKey: storageKey)
    }
}
