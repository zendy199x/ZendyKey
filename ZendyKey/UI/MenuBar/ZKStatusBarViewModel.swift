//
//  ZKStatusBarViewModel.swift
//  ZendyKey
//
//  ViewModel for Status Bar
//

import SwiftUI
import Combine
import Cocoa

class ZKStatusBarViewModel: ObservableObject {
    @Published var isVietnameseEnabled = true
    @Published var currentInputMethod: InputMethod = .telex
    @Published var currentCodeTable: CodeTable = .unicode
    @Published var hotkeyDisplay = "⌘⇧V"
    @Published var hotkeyKeyEquivalent: KeyEquivalent = "v"
    @Published var hotkeyModifiers: EventModifiers = [.command, .shift]
    @Published var updateStatus: ZKUpdateStatus = .idle
    @Published var isInputSourceAllowed: Bool = true
    
    private weak var keyboardHandler: ZKKeyboardEventHandler?
    private weak var eventTapManager: ZKEventTapManager?
    
    // Debug logging callback
    var debugLogCallback: ((String) -> Void)?
    
    var onOpenPreferences: (() -> Void)?
    var onOpenMacroManagement: (() -> Void)?
    var onOpenZKConvertTool: (() -> Void)?
    
    init(keyboardHandler: ZKKeyboardEventHandler?, eventTapManager: ZKEventTapManager?) {
        self.keyboardHandler = keyboardHandler
        self.eventTapManager = eventTapManager
        
        // Sync initial state with keyboard handler
        if let handler = keyboardHandler {
            handler.setVietnamese(isVietnameseEnabled)
        }
        
        // Load hotkey from preferences
        updateHotkeyDisplay()
    }
    
    private func log(_ message: String) {
        debugLogCallback?(message)
    }
    
    func toggleVietnamese() {
        isVietnameseEnabled.toggle()
        keyboardHandler?.setVietnamese(isVietnameseEnabled)
        log("🔄 Vietnamese toggled: \(isVietnameseEnabled ? "ON" : "OFF")")
        
        // Play toggle sound via SoundManager
        ZKSoundManager.shared.playToggleSound(enabled: isVietnameseEnabled)
        
        // Notify Settings panel to update toggle with animation
        NotificationCenter.default.post(
            name: .vietnameseModeDidChange,
            object: nil,
            userInfo: ["enabled": isVietnameseEnabled]
        )
        
        // Save language for current app (Smart Switch)
        saveLanguageForCurrentApp()
    }
    
    /// Set Vietnamese enabled state directly (used by inline toggle in header)
    func setVietnameseEnabled(_ enabled: Bool) {
        guard enabled != isVietnameseEnabled else { return }
        isVietnameseEnabled = enabled
        keyboardHandler?.setVietnamese(enabled)
        log("🔄 Vietnamese set to: \(enabled ? "ON" : "OFF")")
        
        // Notify Settings panel to update toggle with animation
        NotificationCenter.default.post(
            name: .vietnameseModeDidChange,
            object: nil,
            userInfo: ["enabled": enabled]
        )
        
        // Save language for current app (Smart Switch)
        saveLanguageForCurrentApp()
    }
    
    /// Save current language for the active app (for Smart Switch feature)
    private func saveLanguageForCurrentApp() {
        guard let handler = keyboardHandler else { return }
        guard handler.smartSwitchEnabled else { return }

        // Check if overlay app detection is enabled
        let prefs = ZKSharedSettings.shared.loadPreferences()
        if prefs.detectOverlayApps {
            // Check if an overlay app (Spotlight/Raycast/Alfred) is currently visible
            if ZKOverlayAppDetector.shared.isOverlayAppVisible() {
                if let overlayName = ZKOverlayAppDetector.shared.getVisibleOverlayAppName() {
                    log("⚠️ Smart Switch: Skipping save (overlay app '\(overlayName)' is active)")
                } else {
                    log("⚠️ Smart Switch: Skipping save (overlay app detected)")
                }
                // Don't save language preference when overlay is active
                // This prevents overwriting the underlying app's language setting
                return
            }
        }

        guard let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return }

        let language = isVietnameseEnabled ? 1 : 0
        handler.engine.saveAppLanguage(bundleId: bundleId, language: language)
        log("📝 Smart Switch: Saved '\(bundleId)' → \(isVietnameseEnabled ? "Vietnamese" : "English")")
    }
    
    func selectInputMethod(_ method: InputMethod) {
        log("📋 selectInputMethod: BEFORE=\(currentInputMethod.displayName), setting to \(method.displayName)")
        
        currentInputMethod = method
        
        log("📋 selectInputMethod: AFTER=\(currentInputMethod.displayName)")
        
        if let handler = keyboardHandler {
            handler.inputMethod = method
            log("✅ Set handler.inputMethod to \(method.displayName)")
        } else {
            log("⚠️ keyboardHandler is nil!")
        }
        
        // Save to preferences
        var prefs = ZKSharedSettings.shared.loadPreferences()
        prefs.inputMethod = method
        ZKSharedSettings.shared.savePreferences(prefs)
        
        // Notify Settings panel to update with animation
        NotificationCenter.default.post(name: .ZendyKeySettingsDidChange, object: nil)

        // Verify saved
        let savedPrefs = ZKSharedSettings.shared.loadPreferences()
        log("📋 Saved to prefs, verified: \(savedPrefs.inputMethod.displayName)")
    }
    
    func selectCodeTable(_ table: CodeTable) {
        log("📋 selectCodeTable: setting to \(table.displayName)")
        
        currentCodeTable = table
        keyboardHandler?.codeTable = table
        
        // Save to preferences
        var prefs = ZKSharedSettings.shared.loadPreferences()
        prefs.codeTable = table
        ZKSharedSettings.shared.savePreferences(prefs)
        
        // Notify Settings panel to update with animation
        NotificationCenter.default.post(name: .ZendyKeySettingsDidChange, object: nil)
        
        // Save code table for current app (Remember Code Table Per App - OpenKey vRememberCode)
        saveCodeTableForCurrentApp()
        
        log("✅ CodeTable set to \(table.displayName)")
    }
    
    /// Save current code table for the active app (for Remember Code Table Per App feature)
    private func saveCodeTableForCurrentApp() {
        let prefs = ZKSharedSettings.shared.loadPreferences()
        guard prefs.rememberCodeTablePerApp else { return }
        
        guard let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return }
        
        // Skip saving for ZendyKey itself
        if bundleId.contains("ZendyKey") { return }
        
        ZKPerAppCodeTableManager.shared.setCodeTable(forBundleId: bundleId, codeTable: currentCodeTable.rawValue)
        log("📝 Per-App Code Table: Saved '\(bundleId)' → \(currentCodeTable.displayName)")
    }
    
    /// Restore code table for the given app (called when app switches)
    func restoreCodeTableForApp(bundleId: String) {
        let prefs = ZKSharedSettings.shared.loadPreferences()
        guard prefs.rememberCodeTablePerApp else { return }
        
        // Skip for ZendyKey itself
        if bundleId.contains("ZendyKey") { return }
        
        if let savedCodeTableRaw = ZKPerAppCodeTableManager.shared.getCodeTable(forBundleId: bundleId),
           let savedCodeTable = CodeTable(rawValue: savedCodeTableRaw),
           savedCodeTable != currentCodeTable {
            log("🔄 Per-App Code Table: Restoring '\(bundleId)' → \(savedCodeTable.displayName)")
            
            currentCodeTable = savedCodeTable
            keyboardHandler?.codeTable = savedCodeTable
            
            // Also update preferences
            var newPrefs = ZKSharedSettings.shared.loadPreferences()
            newPrefs.codeTable = savedCodeTable
            ZKSharedSettings.shared.savePreferences(newPrefs)
        }
    }
    
    func openPreferences() {
        onOpenPreferences?()
    }
    
    func openMacroManagement() {
        onOpenMacroManagement?()
    }
    
    func openZKConvertTool() {
        onOpenZKConvertTool?()
    }
    
    func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func openStatistics() {
        // Open settings with statistics section selected
        if #available(macOS 13.0, *) {
            ZKAppDelegate.shared?.openSettingsWithSection(.statistics)
        } else {
            // Fallback for older macOS - just open preferences
            ZKAppDelegate.shared?.openPreferences()
        }
    }
    
    func updateHotkeyDisplay(_ hotkey: Hotkey? = nil) {
        let hotkeyToUse = hotkey ?? ZKSharedSettings.shared.loadPreferences().toggleHotkey
        
        // Update display string
        hotkeyDisplay = hotkeyToUse.displayString
        
        // For modifier-only hotkeys, don't set keyEquivalent (menu won't show shortcut)
        if hotkeyToUse.isModifierOnly {
            hotkeyKeyEquivalent = KeyEquivalent("\0")  // Null character - no key equivalent
        } else {
            hotkeyKeyEquivalent = keyCodeToKeyEquivalent(hotkeyToUse.keyCode)
        }
        hotkeyModifiers = modifierFlagsToEventModifiers(hotkeyToUse.modifiers)
    }
    
    private func keyCodeToKeyEquivalent(_ keyCode: UInt16) -> KeyEquivalent {
        let mapping: [UInt16: KeyEquivalent] = [
            0x00: "a", 0x0B: "b", 0x08: "c", 0x02: "d", 0x0E: "e",
            0x03: "f", 0x05: "g", 0x04: "h", 0x22: "i", 0x26: "j",
            0x28: "k", 0x25: "l", 0x2E: "m", 0x2D: "n", 0x1F: "o",
            0x23: "p", 0x0C: "q", 0x0F: "r", 0x01: "s", 0x11: "t",
            0x20: "u", 0x09: "v", 0x0D: "w", 0x07: "x", 0x10: "y",
            0x06: "z",
            0x31: " "
        ]
        return mapping[keyCode] ?? "v"
    }
    
    private func modifierFlagsToEventModifiers(_ flags: ModifierFlags) -> EventModifiers {
        var modifiers: EventModifiers = []
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        return modifiers
    }
}
