//
//  ZKTextInjector.swift
//  ZendyKey
//
//  Advanced text injection with multiple methods
//

import Cocoa
import Carbon.HIToolbox
import ApplicationServices

// MARK: - Injection Method

enum ZKInjectionMethod: String, CaseIterable {
    case fast           // Default backspace + text via CGEvent
    case slow           // Higher delays for Terminals/Electron apps
    case selection      // Shift+Left select + type (browser address bars)
    case autocomplete   // Forward Delete + backspace + text (Spotlight)
    case axDirect       // AX API direct text manipulation (Spotlight/Arc)
    case selectAll      // Cmd+A + type full buffer (aggressive autocomplete)
    
    var displayName: String {
        switch self {
        case .fast: return "Fast (Default)"
        case .slow: return "Slow (Terminal)"
        case .selection: return "Selection"
        case .autocomplete: return "Autocomplete Fix"
        case .axDirect: return "AX Direct"
        case .selectAll: return "Select All"
        }
    }
}

// MARK: - Text Injector

class ZKTextInjector {
    static let shared = ZKTextInjector()
    
    // Session buffer tracks full committed text for selectAll injection
    private var sessionBuffer: String = ""
    private var skipWordRestoreAfterClick = false
    
    // Timing configuration
    private var fastDelay: UInt32 = 1000       // 1ms
    private var slowDelay: UInt32 = 5000       // 5ms
    private var selectionDelay: UInt32 = 10000 // 10ms
    
    private init() {}
    
    // MARK: - Public API
    
    /// Main injection entry point
    func inject(backspaceCount: Int, text: String, method: ZKInjectionMethod) {
        switch method {
        case .fast:
            injectFast(bs: backspaceCount, text: text)
        case .slow:
            injectSlow(bs: backspaceCount, text: text)
        case .selection:
            injectSelection(bs: backspaceCount, text: text)
        case .autocomplete:
            injectAutocomplete(bs: backspaceCount, text: text)
        case .axDirect:
            if #available(macOS 13.0, *) {
                injectAXDirect(bs: backspaceCount, text: text)
            } else {
                injectFast(bs: backspaceCount, text: text)
            }
        case .selectAll:
            injectSelectAll(text: text)
        }
        
        // Update session buffer
        updateSessionBuffer(backspace: backspaceCount, newText: text)
    }
    
    /// Clear session buffer (called on word break, app switch, etc.)
    func clearSessionBuffer() {
        sessionBuffer = ""
    }
    
    /// Mark that mouse was clicked (skip word restore)
    func markMouseClicked() {
        skipWordRestoreAfterClick = true
    }
    
    /// Reset mouse click flag
    func resetMouseClickFlag() {
        skipWordRestoreAfterClick = false
    }
    
    /// Check if should skip word restore after click
    var shouldSkipWordRestore: Bool {
        return skipWordRestoreAfterClick
    }
    
    // MARK: - Injection Methods
    
    /// Fast injection: simple backspace + text
    private func injectFast(bs: Int, text: String) {
        for _ in 0..<bs {
            postKey(keyCode: 0x33, flags: []) // Backspace
            usleep(fastDelay)
        }
        
        postString(text, delay: fastDelay)
    }
    
    /// Slow injection: higher delays for problematic apps
    private func injectSlow(bs: Int, text: String) {
        for _ in 0..<bs {
            postKey(keyCode: 0x33, flags: []) // Backspace
            usleep(slowDelay)
        }
        
        usleep(slowDelay * 2) // Extra pause before text
        postString(text, delay: slowDelay)
    }
    
    /// Selection injection: Shift+Left to select, then type replacement
    private func injectSelection(bs: Int, text: String) {
        guard bs > 0 else {
            postString(text, delay: fastDelay)
            return
        }
        
        // Select characters with Shift+Left
        for _ in 0..<bs {
            postKey(keyCode: 0x7B, flags: [.maskShift]) // Left arrow with Shift
            usleep(selectionDelay)
        }
        
        usleep(selectionDelay * 2)
        
        // Type replacement (overwrites selection)
        postString(text, delay: fastDelay)
    }
    
    /// Autocomplete injection: Forward Delete + backspace + text
    private func injectAutocomplete(bs: Int, text: String) {
        // First, press Forward Delete to clear any autocomplete suggestion
        postKey(keyCode: 0x75, flags: []) // Forward Delete (Fn+Delete)
        usleep(slowDelay)
        
        // Then normal backspace + type
        injectFast(bs: bs, text: text)
    }
    
    /// AX Direct injection: Use Accessibility API to set text directly
    @available(macOS 13.0, *)
    private func injectAXDirect(bs: Int, text: String) {
        // Get focused element
        guard let focusedElement = getFocusedElement() else {
            // Fallback to fast method
            injectFast(bs: bs, text: text)
            return
        }
        
        // Get current text value
        var currentValue: AnyObject?
        AXUIElementCopyAttributeValue(focusedElement, kAXValueAttribute as CFString, &currentValue)
        
        guard let currentText = currentValue as? String else {
            injectFast(bs: bs, text: text)
            return
        }
        
        // Get cursor position
        var selectedRange: AnyObject?
        AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, &selectedRange)
        
        guard selectedRange != nil else {
            injectFast(bs: bs, text: text)
            return
        }
        let rangeValue = selectedRange as! AXValue
        
        var range = CFRange()
        AXValueGetValue(rangeValue, .cfRange, &range)
        
        // Calculate new text
        let cursorPos = range.location
        let startIndex = max(0, cursorPos - bs)
        
        let prefix = String(currentText.prefix(startIndex))
        let suffix = String(currentText.dropFirst(cursorPos))
        let newText = prefix + text + suffix
        
        // Set new text
        AXUIElementSetAttributeValue(focusedElement, kAXValueAttribute as CFString, newText as CFTypeRef)
        
        // Move cursor to end of inserted text
        let newCursorPos = startIndex + text.count
        var newRange = CFRange(location: newCursorPos, length: 0)
        if let newRangeValue = AXValueCreate(.cfRange, &newRange) {
            AXUIElementSetAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, newRangeValue)
        }
    }
    
    /// Select All injection: Cmd+A then type full buffer
    private func injectSelectAll(text: String) {
        // Select all with Cmd+A
        postKey(keyCode: 0x00, flags: [.maskCommand]) // Cmd+A
        usleep(selectionDelay)
        
        // Type full session buffer + new text
        postString(sessionBuffer + text, delay: fastDelay)
    }
    
    // MARK: - Session Buffer
    
    private func updateSessionBuffer(backspace: Int, newText: String) {
        // Remove backspaced characters from session buffer
        if backspace > 0 && sessionBuffer.count >= backspace {
            sessionBuffer = String(sessionBuffer.dropLast(backspace))
        }
        
        // Append new text
        sessionBuffer += newText
    }
    
    // MARK: - Word Restore (AX API)
    
    /// Get word before cursor for restore on backspace
    func getWordToRestoreOnBackspace() -> String? {
        guard !skipWordRestoreAfterClick else { return nil }
        
        // Get focused element
        guard let focusedElement = getFocusedElement() else { return nil }
        
        // Get text value
        var currentValue: AnyObject?
        AXUIElementCopyAttributeValue(focusedElement, kAXValueAttribute as CFString, &currentValue)
        guard let currentText = currentValue as? String else { return nil }
        
        // Get cursor position
        var selectedRange: AnyObject?
        AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, &selectedRange)
        guard selectedRange != nil else { return nil }
        let rangeValue = selectedRange as! AXValue
        
        var range = CFRange()
        guard AXValueGetValue(rangeValue, .cfRange, &range) else { return nil }
        
        let cursorPos = range.location
        
        // Check if cursor is at word boundary (after space)
        guard cursorPos > 0 else { return nil }
        
        let textBeforeCursor = String(currentText.prefix(cursorPos))
        
        // Check if last char is space (we just deleted it)
        // Look for word before that space
        let trimmed = textBeforeCursor.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        // Extract last word
        let components = trimmed.components(separatedBy: .whitespaces)
        guard let lastWord = components.last, !lastWord.isEmpty else { return nil }
        
        return lastWord
    }
    
    // MARK: - Helpers
    
    private func getFocusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: AnyObject?
        
        let result = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        guard result == .success, let appElement = focusedApp else { return nil }
        
        var focusedElement: AnyObject?
        let elementResult = AXUIElementCopyAttributeValue(appElement as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        guard elementResult == .success else { return nil }
        
        return focusedElement as! AXUIElement?
    }
    
    private func postKey(keyCode: UInt16, flags: CGEventFlags) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = flags
            keyDown.post(tap: .cghidEventTap)
        }
        
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = flags
            keyUp.post(tap: .cghidEventTap)
        }
    }
    
    private func postString(_ string: String, delay: UInt32) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        for char in string {
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                var utf16 = Array(String(char).utf16)
                event.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
                event.post(tap: .cghidEventTap)
            }
            
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                event.post(tap: .cghidEventTap)
            }
            
            usleep(delay)
        }
    }
}

// MARK: - App-Specific Injection Configuration

struct ZKAppInjectionConfig {
    let bundleId: String
    let method: ZKInjectionMethod
    
    static let defaultConfigs: [ZKAppInjectionConfig] = [
        // Terminals need slow injection
        ZKAppInjectionConfig(bundleId: "com.apple.Terminal", method: .slow),
        ZKAppInjectionConfig(bundleId: "com.googlecode.iterm2", method: .slow),
        ZKAppInjectionConfig(bundleId: "io.alacritty", method: .slow),
        ZKAppInjectionConfig(bundleId: "com.github.wez.wezterm", method: .slow),
        
        // Browser address bars need selection injection
        ZKAppInjectionConfig(bundleId: "com.apple.Safari", method: .selection),
        ZKAppInjectionConfig(bundleId: "com.google.Chrome", method: .selection),
        ZKAppInjectionConfig(bundleId: "org.mozilla.firefox", method: .selection),
        ZKAppInjectionConfig(bundleId: "company.thebrowser.Browser", method: .selection), // Arc
        
        // Spotlight/Alfred/Raycast need autocomplete fix
        ZKAppInjectionConfig(bundleId: "com.apple.Spotlight", method: .autocomplete),
        ZKAppInjectionConfig(bundleId: "com.runningwithcrayons.Alfred", method: .autocomplete),
        ZKAppInjectionConfig(bundleId: "com.raycast.macos", method: .autocomplete),
    ]
    
    static func getMethod(for bundleId: String) -> ZKInjectionMethod {
        if let config = defaultConfigs.first(where: { $0.bundleId == bundleId }) {
            return config.method
        }
        return .fast
    }
}
