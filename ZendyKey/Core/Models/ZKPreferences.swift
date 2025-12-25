//
//  Preferences.swift
//  ZendyKey
//
//  User preferences and settings
//

import Foundation
import Cocoa

// MARK: - Menu Bar Icon Style

enum MenuBarIconStyle: String, Codable, CaseIterable {
    case x = "X"
    case v = "V"
    
    var displayName: String {
        switch self {
        case .x: return "Chữ X"
        case .v: return "Chữ V"
        }
    }
}

// MARK: - Restore Key Options

enum RestoreKey: UInt16, Codable, CaseIterable, Identifiable {
    case esc = 53      // ESC key code
    case option = 58   // Option key code
    case control = 59  // Control key code
    case command = 55  // Command key code
    
    var id: UInt16 { rawValue }
    
    var displayName: String {
        switch self {
        case .esc: return "ESC"
        case .option: return "Option (⌥)"
        case .control: return "Control (⌃)"
        case .command: return "Command (⌘)"
        }
    }
    
    var symbol: String {
        switch self {
        case .esc: return "⎋"
        case .option: return "⌥"
        case .control: return "⌃"
        case .command: return "⌘"
        }
    }
}

// MARK: - SendKeyStepByStep App Model

struct SendKeyStepByStepApp: Codable, Identifiable, Equatable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let name: String
    let path: String
    
    init(bundleIdentifier: String, name: String, path: String) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.path = path
    }
    
    init?(from url: URL) {
        guard let bundle = Bundle(url: url),
              let bundleId = bundle.bundleIdentifier else {
            return nil
        }
        self.bundleIdentifier = bundleId
        self.name = FileManager.default.displayName(atPath: url.path)
        self.path = url.path
    }
}



struct Preferences: Codable {
    // Hotkey settings
    var toggleHotkey: Hotkey = Hotkey(keyCode: 9, modifiers: [.command, .shift]) // Default: Cmd+Shift+V
    var inputMethodHotkey: Hotkey? = nil  // Optional: Hotkey to switch input method
    var codeTableHotkey: Hotkey? = nil    // Optional: Hotkey to switch code table
    var beepOnToggle: Bool = false               // Play beep sound when toggle Vietnamese
    var beepVolume: Double = 0.5                 // Beep volume (0.0 to 1.0)
    var showOnScreenIndicator: Bool = true       // Show floating indicator when toggle mode
    
    // Input settings
    var inputMethod: InputMethod = .telex
    var codeTable: CodeTable = .unicode
    var modernStyle: Bool = false
    var spellCheckEnabled: Bool = false
    var grammarCheckEnabled: Bool = true       // Auto-fix grammar: ưo→ươ, mark position adjustment
    var fixAutocomplete: Bool = true
    var autoRestoreEnglishEnabled: Bool = false  // Auto-restore English when foreign pattern detected
    var rememberCodeTable: Bool = true           // Remember code table between sessions
    
    // Advanced features
    var quickTelexEnabled: Bool = true           // cc→ch, gg→gi, etc.
    var quickStartConsonantEnabled: Bool = false // f→ph, j→gi, w→qu
    var quickEndConsonantEnabled: Bool = false   // g→ng, h→nh, k→ch
    var upperCaseFirstChar: Bool = false         // Auto capitalize first letter
    var restoreIfWrongSpelling: Bool = true      // Restore if wrong spelling
    var allowConsonantZFWJ: Bool = false         // Allow Z, F, W, J consonants
    var freeMarkEnabled: Bool = false            // Free mark placement (đặt dấu tự do)
    var tempOffSpellingEnabled: Bool = false     // Temp off spelling with modifier key
    var tempOffSpellingKey: UInt16 = 58          // Default: Option key (keyCode 58)
    var skipWShortcut: Bool = false              // Skip w→ư conversion in Telex (keep 'w' as 'w')
    var freeToneEnabled: Bool = false            // Free tone placement without validation
    var perAppModeEnabled: Bool = false          // Remember language mode per application
    var rememberCodeTablePerApp: Bool = true     // Remember code table per app (OpenKey vRememberCode)
    var preserveVietnameseModeWithOtherLanguage: Bool = true  // Preserve Vietnamese when using non-Latin keyboard (OpenKey vOtherLanguage)
    
    // Restore key configuration
    var restoreOnEscape: Bool = true             // Enable restore to raw keys
    var restoreKey: RestoreKey = .esc            // Key to restore raw input
    
    // Pause key configuration (Tạm tắt gõ tiếng Việt)
    var pauseKeyEnabled: Bool = false            // Hold key to temporarily switch to English
    var pauseKey: UInt16 = 59                    // Default: Control key
    var pauseKeyName: String = "Control"         // Display name for pause key
    
    // Macro settings
    var macroEnabled: Bool = false               // Enable text shortcuts
    var macroInEnglishMode: Bool = false         // Use macro in English mode
    var autoCapsMacro: Bool = false              // Auto capitalize macro output
    
    // Compatibility settings
    var sendKeyStepByStep: Bool = false          // Global step-by-step key sending
    var fixChromiumBrowser: Bool = true          // Fix Chromium browser issues
    var performLayoutCompat: Bool = false        // Layout compatibility mode
    
    // Smart switch settings
    var smartSwitchEnabled: Bool = false         // Remember language per app
    var detectOverlayApps: Bool = false          // Detect Spotlight/Raycast/Alfred overlay apps
    var inputSourceAutoSwitch: Bool = true       // Auto-disable for non-Latin input sources
    
    // Debug settings
    var debugModeEnabled: Bool = false           // Show debug window (even in production)
    
    // IMKit settings (experimental)
    var imkitEnabled: Bool = false               // Use IMKit instead of CGEvent injection
    var imkitUseMarkedText: Bool = false         // Show underline when composing (IMKit mode)
    var switchToZendyKeyHotkey: Hotkey?              // Hotkey to quickly switch to ZKIMMain input source
    
    // UI settings
    var showDockIcon: Bool = false               // Show icon in Dock (menu bar always visible)
    var startAtLogin: Bool = false
    var menuBarIconStyle: MenuBarIconStyle = .x  // Icon style for menubar
    var useVietnameseMenubarIcon: Bool = false   // Use V icon when Vietnamese mode
    var menuBarIconSize: Double = 18.0           // Menu bar icon size in pixels
    
    // Excluded apps - apps where Vietnamese input is disabled
    var excludedApps: [ExcludedApp] = []
    
    // SendKeyStepByStep apps
    var sendKeyStepByStepApps: [SendKeyStepByStepApp] = []
}

// MARK: - Excluded App Model

struct ExcludedApp: Codable, Identifiable, Equatable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let appName: String
    let appPath: String?
    
    init(bundleIdentifier: String, appName: String, appPath: String? = nil) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.appPath = appPath
    }
}

struct Hotkey: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: ModifierFlags
    var isModifierOnly: Bool  // True if hotkey is just modifiers (e.g., Ctrl+Shift)
    
    init(keyCode: UInt16, modifiers: ModifierFlags, isModifierOnly: Bool = false) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isModifierOnly = isModifierOnly
    }
    
    var displayString: String {
        var parts: [String] = []
        
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        
        // For modifier-only hotkeys, don't add key character
        if isModifierOnly {
            return parts.joined()
        }
        
        // Convert keyCode to character
        if let char = keyCodeToCharacter(keyCode) {
            parts.append(char.uppercased())
        } else if keyCode != 0 {
            parts.append("?")
        }
        
        return parts.joined()
    }
    
    private func keyCodeToCharacter(_ keyCode: UInt16) -> String? {
        let mapping: [UInt16: String] = [
            0x00: "A", 0x0B: "B", 0x08: "C", 0x02: "D", 0x0E: "E",
            0x03: "F", 0x05: "G", 0x04: "H", 0x22: "I", 0x26: "J",
            0x28: "K", 0x25: "L", 0x2E: "M", 0x2D: "N", 0x1F: "O",
            0x23: "P", 0x0C: "Q", 0x0F: "R", 0x01: "S", 0x11: "T",
            0x20: "U", 0x09: "V", 0x0D: "W", 0x07: "X", 0x10: "Y",
            0x06: "Z",
            0x31: "Space", 0x24: "Return", 0x35: "Esc"
        ]
        return mapping[keyCode]
    }
    
    /// Returns the key character for use with NSMenuItem.keyEquivalent (lowercase)
    var keyEquivalentString: String {
        if isModifierOnly { return "" }
        if let char = keyCodeToCharacter(keyCode) {
            return char.lowercased()
        }
        return ""
    }
}

struct ModifierFlags: OptionSet, Codable {
    let rawValue: UInt
    
    static let control = ModifierFlags(rawValue: 1 << 0)
    static let option = ModifierFlags(rawValue: 1 << 1)
    static let shift = ModifierFlags(rawValue: 1 << 2)
    static let command = ModifierFlags(rawValue: 1 << 3)
    
    init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    init(from eventFlags: NSEvent.ModifierFlags) {
        var flags: ModifierFlags = []
        if eventFlags.contains(.control) { flags.insert(.control) }
        if eventFlags.contains(.option) { flags.insert(.option) }
        if eventFlags.contains(.shift) { flags.insert(.shift) }
        if eventFlags.contains(.command) { flags.insert(.command) }
        self = flags
    }
}
