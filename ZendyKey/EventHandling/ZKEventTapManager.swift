//
//  ZKEventTapManager.swift
//  ZendyKey
//
//  Manages CGEventTap for intercepting keyboard events
//

import Cocoa
import Carbon

class ZKEventTapManager {

    // MARK: - Properties

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isEnabled = false
    private var isSuspended = false  // Track suspension state for IMKit mode

    weak var delegate: EventTapDelegate?
    var debugLogCallback: ((String) -> Void)?
    
    // Toggle hotkey configuration
    var toggleHotkey: Hotkey?
    var onToggleHotkey: (() -> Void)?
    
    // Input method hotkey configuration
    var inputMethodHotkey: Hotkey?
    var onInputMethodHotkey: (() -> Void)?
    
    // Code table hotkey configuration
    var codeTableHotkey: Hotkey?
    var onCodeTableHotkey: (() -> Void)?
    
    // MARK: - Modifier Key Features (Pause, Restore, Temp Off Spelling)
    
    // Pause key configuration (hold to temporarily switch to English)
    var pauseKeyEnabled: Bool = false
    var pauseKeyCode: UInt16 = 59  // Default: Control key
    var onPauseKeyDown: (() -> Void)?
    var onPauseKeyUp: (() -> Void)?
    
    // Restore key configuration (press to restore original text without tones)
    var restoreKeyEnabled: Bool = false
    var restoreKeyCode: UInt16 = 53  // Default: ESC key
    var onRestoreKeyPressed: ((CGEventTapProxy) -> Bool)?  // Returns true if restore was performed
    
    // Temp off spelling configuration (hold to temporarily disable spell check)
    var tempOffSpellingEnabled: Bool = false
    var tempOffSpellingKey: UInt16 = 58  // Default: Option key
    var onTempOffSpellingStateChange: ((Bool) -> Void)?  // true = pressed, false = released
    
    // Recording mode - when true, hotkeys are bypassed to allow recording new hotkeys
    var isRecordingHotkey: Bool = false
    
    // MARK: - State Tracking
    
    // Modifier-only hotkey tracking
    private var modifierOnlyState: ModifierOnlyState = ModifierOnlyState()
    
    private struct ModifierOnlyState {
        var currentModifiers: ModifierFlags = []
        var targetModifiersReached: Bool = false  // True when all required modifiers were pressed
        var hasTriggered: Bool = false
    }
    
    // Pause key state tracking
    private var pauseKeyState: PauseKeyState = PauseKeyState()
    
    private struct PauseKeyState {
        var isHolding: Bool = false
        var lastKeyCode: UInt16 = 0
        var hadOtherKeyPress: Bool = false  // Track if another key was pressed while holding (e.g., Ctrl+C)
    }
    
    // Temp off spelling state tracking
    private var tempOffSpellingState: TempOffSpellingState = TempOffSpellingState()
    
    private struct TempOffSpellingState {
        var isHolding: Bool = false
    }
    
    // MARK: - Delegate Protocol

    protocol EventTapDelegate: AnyObject {
        func shouldProcessEvent(_ event: CGEvent, type: CGEventType) -> Bool
        func processKeyEvent(_ event: CGEvent, type: CGEventType, proxy: CGEventTapProxy) -> CGEvent?
    }
    
    // MARK: - Errors
    
    enum EventTapError: Error {
        case creationFailed
        case accessibilityPermissionDenied
        case alreadyRunning
        case notRunning
    }
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    func start() throws {
        debugLogCallback?("🚀 ZKEventTapManager.start() called")

        guard !isEnabled else {
            debugLogCallback?("  ❌ Already running")
            throw EventTapError.alreadyRunning
        }

        // Check accessibility permission
        guard checkAccessibilityPermission() else {
            debugLogCallback?("  ❌ No accessibility permission")
            throw EventTapError.accessibilityPermissionDenied
        }
        debugLogCallback?("  ✅ Accessibility permission OK")

        // Create event mask for keyboard events
        let eventMask: CGEventMask = (
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)
        )
        debugLogCallback?("  📊 Event mask: \(eventMask)")
        
        // Create event tap
        debugLogCallback?("  🔧 Creating event tap...")
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }

                let manager = Unmanaged<ZKEventTapManager>.fromOpaque(refcon).takeUnretainedValue()

                // Call event callback with proxy and handle nil (consume event)
                if let result = manager.eventCallback(proxy: proxy, type: type, event: event) {
                    return result
                } else {
                    // Return nil to consume the event
                    return nil
                }
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            debugLogCallback?("  ❌ Failed to create event tap!")
            throw EventTapError.creationFailed
        }
        debugLogCallback?("  ✅ Event tap created")
        
        eventTap = tap

        // Create run loop source
        debugLogCallback?("  🔄 Creating run loop source...")
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        guard let source = runLoopSource else {
            debugLogCallback?("  ❌ Failed to create run loop source")
            eventTap = nil
            throw EventTapError.creationFailed
        }
        debugLogCallback?("  ✅ Run loop source created")

        // Add to current run loop
        debugLogCallback?("  🔄 Adding to run loop...")
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        debugLogCallback?("  ✅ Added to run loop")

        // Enable the event tap
        debugLogCallback?("  ⚡ Enabling event tap...")
        CGEvent.tapEnable(tap: tap, enable: true)
        debugLogCallback?("  ✅ Event tap enabled")

        isEnabled = true
        debugLogCallback?("✅ Event tap fully started!")
    }

    func stop() {
        guard isEnabled else { return }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            // CFRelease not needed in modern Swift - ARC handles it
            eventTap = nil
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            // CFRelease not needed in modern Swift - ARC handles it
            runLoopSource = nil
        }
        
        isEnabled = false
        
        debugLogCallback?("⏹️ Event tap stopped")
    }
    
    func restart() throws {
        stop()
        try start()
    }

    /// Suspend event tap temporarily (for IMKit mode)
    func suspend() {
        guard isEnabled else { return }

        isSuspended = true
        debugLogCallback?("⏸️ Event tap suspended (IMKit active)")
    }

    /// Resume event tap (when leaving IMKit mode)
    func resume() {
        guard isEnabled else { return }

        isSuspended = false
        debugLogCallback?("▶️ Event tap resumed (IMKit inactive)")
    }

    // MARK: - Event Callback
    
    private func eventCallback(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        // IMPORTANT: If suspended (IMKit mode active), pass ALL events through
        // This allows IMKit to receive and handle keyboard events
        if isSuspended {
            return Unmanaged.passUnretained(event)
        }

        debugLogCallback?("ZKEventTapManager.eventCallback: type=\(type.rawValue), delegate=\(delegate != nil)")

        // Handle tap disabled event
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        // Pause key handling (hold to temporarily switch to English)
        // NOTE: This does NOT interfere with Ctrl+C because we don't consume the event.
        // We just pause Vietnamese processing while the modifier is held.
        if pauseKeyEnabled && type == .flagsChanged {
            let flags = event.flags
            let isPauseKeyPressed: Bool
            
            debugLogCallback?("🔑 PAUSE KEY DEBUG: pauseKeyEnabled=\(pauseKeyEnabled), pauseKeyCode=\(pauseKeyCode), flags=\(flags.rawValue)")
            
            // Check if the configured pause key is pressed based on flags
            switch pauseKeyCode {
            case 58:  // Option key
                isPauseKeyPressed = flags.contains(.maskAlternate)
                debugLogCallback?("  → Checking Option: maskAlternate=\(flags.contains(.maskAlternate))")
            case 59:  // Control key
                isPauseKeyPressed = flags.contains(.maskControl)
                debugLogCallback?("  → Checking Control: maskControl=\(flags.contains(.maskControl))")
            case 55:  // Command key
                isPauseKeyPressed = flags.contains(.maskCommand)
                debugLogCallback?("  → Checking Command: maskCommand=\(flags.contains(.maskCommand))")
            default:
                isPauseKeyPressed = false
                debugLogCallback?("  → Unknown pauseKeyCode: \(pauseKeyCode)")
            }
            
            debugLogCallback?("  → isPauseKeyPressed=\(isPauseKeyPressed), isHolding=\(pauseKeyState.isHolding)")
            
            if isPauseKeyPressed && !pauseKeyState.isHolding {
                // Pause key pressed - switch to English temporarily
                pauseKeyState.isHolding = true
                pauseKeyState.lastKeyCode = pauseKeyCode
                pauseKeyState.hadOtherKeyPress = false
                let keyName = getKeyName(pauseKeyCode)
                debugLogCallback?("⏸️ Pause key (\(keyName)) pressed - temporarily switching to English")
                DispatchQueue.main.async { [weak self] in
                    self?.onPauseKeyDown?()
                }
            } else if !isPauseKeyPressed && pauseKeyState.isHolding {
                // Pause key released - restore previous mode
                pauseKeyState.isHolding = false
                let keyName = getKeyName(pauseKeyCode)
                debugLogCallback?("▶️ Pause key (\(keyName)) released - restoring Vietnamese")
                DispatchQueue.main.async { [weak self] in
                    self?.onPauseKeyUp?()
                }
            }
        }
        
        // Track if user presses any other key while holding pause modifier
        // (kept for potential future use - e.g., combo detection)
        if pauseKeyEnabled && pauseKeyState.isHolding && type == .keyDown {
            pauseKeyState.hadOtherKeyPress = true
        }
        
        // Temp off spelling handling (hold to temporarily disable spell check)
        if tempOffSpellingEnabled && type == .flagsChanged {
            let flags = event.flags
            let isTempOffKeyPressed: Bool
            
            switch tempOffSpellingKey {
            case 58:  // Option key
                isTempOffKeyPressed = flags.contains(.maskAlternate)
            case 59:  // Control key
                isTempOffKeyPressed = flags.contains(.maskControl)
            case 55:  // Command key
                isTempOffKeyPressed = flags.contains(.maskCommand)
            default:
                isTempOffKeyPressed = false
            }
            
            if isTempOffKeyPressed && !tempOffSpellingState.isHolding {
                // Temp off key pressed - disable spell check
                tempOffSpellingState.isHolding = true
                let keyName = getKeyName(tempOffSpellingKey)
                debugLogCallback?("🔤 Temp off spelling key (\(keyName)) pressed - disabling spell check")
                DispatchQueue.main.async { [weak self] in
                    self?.onTempOffSpellingStateChange?(true)
                }
            } else if !isTempOffKeyPressed && tempOffSpellingState.isHolding {
                // Temp off key released - restore spell check
                tempOffSpellingState.isHolding = false
                let keyName = getKeyName(tempOffSpellingKey)
                debugLogCallback?("🔤 Temp off spelling key (\(keyName)) released - restoring spell check")
                DispatchQueue.main.async { [weak self] in
                    self?.onTempOffSpellingStateChange?(false)
                }
            }
        }
        
        // Restore key handling (press to restore original text without tones)
        if restoreKeyEnabled && type == .keyDown {
            let keyCode = event.keyCode
            
            if keyCode == restoreKeyCode {
                // Only process if no other modifiers are pressed (for ESC)
                // For Option/Control, we need special handling
                let flags = event.flags
                let shouldProcess: Bool
                
                switch restoreKeyCode {
                case 53:  // ESC - process with no modifiers
                    shouldProcess = !flags.contains(.maskCommand) && !flags.contains(.maskControl) && !flags.contains(.maskAlternate)
                case 58:  // Option - already handled by flagsChanged, but we handle keyDown too
                    shouldProcess = flags.contains(.maskAlternate) && !flags.contains(.maskCommand) && !flags.contains(.maskControl)
                case 59:  // Control
                    shouldProcess = flags.contains(.maskControl) && !flags.contains(.maskCommand) && !flags.contains(.maskAlternate)
                default:
                    shouldProcess = false
                }
                
                if shouldProcess {
                    let keyName = getKeyName(restoreKeyCode)
                    debugLogCallback?("🔄 Restore key (\(keyName)) pressed - attempting to restore original text")
                    
                    // Call the callback synchronously to check if restore was performed
                    var wasRestored = false
                    if Thread.isMainThread {
                        wasRestored = self.onRestoreKeyPressed?(proxy) ?? false
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            wasRestored = self?.onRestoreKeyPressed?(proxy) ?? false
                        }
                    }
                    
                    if wasRestored {
                        debugLogCallback?("  ✅ Restore successful - consuming event")
                        return nil  // Consume the event
                    } else {
                        debugLogCallback?("  ℹ️ Nothing to restore - passing event through")
                    }
                }
            }
        }

        // Check for toggle hotkey FIRST (before delegate processing)
        // This ensures the hotkey is consumed and doesn't reach other apps
        // Skip hotkey processing if we're in recording mode (user is setting a new hotkey)
        guard !isRecordingHotkey else {
            // In recording mode, pass all events through without processing hotkeys
            if let processedEvent = delegate?.processKeyEvent(event, type: type, proxy: proxy) {
                return Unmanaged.passUnretained(processedEvent)
            }
            return Unmanaged.passUnretained(event)
        }
        
        if let hotkey = toggleHotkey {
            // Handle modifier-only hotkey (e.g., Ctrl+Shift)
            if hotkey.isModifierOnly {
                if type == .flagsChanged {
                    let eventModifiers = ModifierFlags(from: event.flags)
                    
                    debugLogCallback?("  → flagsChanged: eventModifiers=\(eventModifiers.rawValue), hotkey.modifiers=\(hotkey.modifiers.rawValue)")
                    
                    // Check if all required modifiers are currently pressed
                    // Use "contains" to allow for additional modifiers like CapsLock
                    let hasAllRequiredModifiers = hotkey.modifiers.isSubset(of: eventModifiers) &&
                                                   eventModifiers.intersection([.control, .shift, .option, .command]) == hotkey.modifiers
                    
                    if hasAllRequiredModifiers {
                        // All required modifiers are pressed
                        if !modifierOnlyState.targetModifiersReached {
                            modifierOnlyState.targetModifiersReached = true
                            modifierOnlyState.hasTriggered = false
                            debugLogCallback?("  → Target modifiers REACHED: \(hotkey.displayString)")
                        }
                        modifierOnlyState.currentModifiers = eventModifiers
                    } else {
                        // Modifiers changed
                        if modifierOnlyState.targetModifiersReached && !modifierOnlyState.hasTriggered {
                            // Was holding target modifiers, now released - TRIGGER!
                            modifierOnlyState.hasTriggered = true
                            debugLogCallback?("  → MODIFIER-ONLY HOTKEY TRIGGERED on release: \(hotkey.displayString)")
                            DispatchQueue.main.async { [weak self] in
                                self?.onToggleHotkey?()
                            }
                        }
                        // Reset state
                        modifierOnlyState.targetModifiersReached = false
                        modifierOnlyState.currentModifiers = eventModifiers
                    }
                } else if type == .keyDown {
                    // If user presses any key while holding modifiers, cancel the modifier-only hotkey
                    if modifierOnlyState.targetModifiersReached {
                        debugLogCallback?("  → Key pressed while holding modifiers - canceling modifier-only hotkey")
                        modifierOnlyState.targetModifiersReached = false
                        modifierOnlyState.hasTriggered = true  // Prevent trigger on release
                    }
                }
                // Don't consume flagsChanged events - let them pass through
            } else {
                // Handle regular hotkey (e.g., Cmd+Shift+V)
                if type == .keyDown {
                    let eventModifiers = ModifierFlags(from: event.flags)
                    if event.keyCode == hotkey.keyCode && eventModifiers == hotkey.modifiers {
                        debugLogCallback?("  → TOGGLE HOTKEY DETECTED - consuming event")
                        // Call toggle callback on main thread
                        DispatchQueue.main.async { [weak self] in
                            self?.onToggleHotkey?()
                        }
                        // Consume the event completely - don't pass to other apps
                        return nil
                    }
                }
            }
        }
        
        // Check for input method hotkey
        if let hotkey = inputMethodHotkey, type == .keyDown {
            let eventModifiers = ModifierFlags(from: event.flags)
            if event.keyCode == hotkey.keyCode && eventModifiers == hotkey.modifiers {
                debugLogCallback?("  → INPUT METHOD HOTKEY DETECTED - consuming event")
                DispatchQueue.main.async { [weak self] in
                    self?.onInputMethodHotkey?()
                }
                return nil
            }
        }
        
        // Check for code table hotkey
        if let hotkey = codeTableHotkey, type == .keyDown {
            let eventModifiers = ModifierFlags(from: event.flags)
            if event.keyCode == hotkey.keyCode && eventModifiers == hotkey.modifiers {
                debugLogCallback?("  → CODE TABLE HOTKEY DETECTED - consuming event")
                DispatchQueue.main.async { [weak self] in
                    self?.onCodeTableHotkey?()
                }
                return nil
            }
        }
        
        // Check for undo typing key (single key, no modifiers required)
        // This is handled by the delegate (ZKKeyboardEventHandler) because it needs
        // to check if there's something to undo in the engine buffer first.
        // If there's nothing to undo, the key should be passed through normally.

        // Handle pause key with Option/Control - inject clean character directly
        // IMPORTANT: This must be BEFORE shouldProcessEvent because that returns false for Control/Option
        // This completely bypasses Vietnamese processing and avoids macOS special character interpretation
        // NOTE: Only apply this for OPTION key, not Control key!
        // - Option+char produces special characters (©, †, ¥) which we want to avoid
        // - Control+char (like Ctrl+C) should pass through for terminal shortcuts
        if pauseKeyEnabled && pauseKeyState.isHolding && type == .keyDown {
            let keyCode = event.keyCode
            
            // Check if this is an event we injected (marked with special flag)
            // We use eventSourceUserData to mark our injected events
            let isInjectedEvent = event.getIntegerValueField(.eventSourceUserData) == 0x5A4B01
            if isInjectedEvent {
                // This is our own injected event - pass it through
                debugLogCallback?("  ↩️ Pause key: passing through our injected event for keyCode \(keyCode)")
                return Unmanaged.passUnretained(event)
            }
            
            debugLogCallback?("🔑 PAUSE KEY INJECT: isHolding=\(pauseKeyState.isHolding), keyCode=\(keyCode), pauseKeyCode=\(pauseKeyCode)")
            
            // Only handle Option pause key - NOT Control!
            // Control+char should pass through for terminal shortcuts (Ctrl+C, Ctrl+Z, etc.)
            if pauseKeyCode == 58 {  // Option key ONLY
                // Create a new clean event without the Option modifier
                // This prevents macOS from outputting special characters like ©, †, ¥
                if let cleanEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) {
                    // Copy original flags but remove Option
                    var newFlags = event.flags
                    newFlags.remove(.maskAlternate)
                    cleanEvent.flags = newFlags
                    
                    // Mark this event so we recognize it and pass through on second encounter
                    cleanEvent.setIntegerValueField(.eventSourceUserData, value: 0x5A4B01)
                    
                    // Post the clean event and consume original
                    cleanEvent.post(tap: .cghidEventTap)
                    debugLogCallback?("  ✅ Option pause key: INJECTED clean character for keyCode \(keyCode)")
                    return nil  // Consume original event
                } else {
                    debugLogCallback?("  ❌ Option pause key: FAILED to create clean event")
                }
            } else if pauseKeyCode == 59 {  // Control key
                // For Control key, pass through normally - don't strip the modifier
                // This allows Ctrl+C, Ctrl+Z, etc. to work in terminal
                debugLogCallback?("  ⏭️ Control pause key: passing through (Ctrl+char shortcuts work normally)")
                return Unmanaged.passUnretained(event)
            } else {
                debugLogCallback?("  ⏭️ Pause key: Skipping (pauseKeyCode \(pauseKeyCode) not handled)")
            }
        }

        // Check if delegate wants to process this event
        guard let delegate = delegate else {
            debugLogCallback?("  → No delegate!")
            return Unmanaged.passUnretained(event)
        }

        debugLogCallback?("  → Calling shouldProcessEvent...")
        guard delegate.shouldProcessEvent(event, type: type) else {
            debugLogCallback?("  → shouldProcessEvent returned false")
            return Unmanaged.passUnretained(event)
        }

        debugLogCallback?("  → Calling processKeyEvent...")
        // Process event through delegate with proxy
        if let processedEvent = delegate.processKeyEvent(event, type: type, proxy: proxy) {
            return Unmanaged.passUnretained(processedEvent)
        }

        // Consume event by returning nil
        return nil
    }
    
    // MARK: - Helper Functions
    
    private func getKeyName(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 53: return "ESC"
        case 55: return "Cmd"
        case 58: return "Option"
        case 59: return "Control"
        default: return "Key(\(keyCode))"
        }
    }
    
    // MARK: - Permission Check
    
    func checkAccessibilityPermission() -> Bool {
        // Don't prompt - just check silently
        // We handle our own permission UI in ZKAppDelegate
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func requestAccessibilityPermission() {
        // This function is kept for compatibility but we don't use it
        // We handle permission requests through our custom dialog
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // MARK: - Status
    
    var isRunning: Bool {
        return isEnabled
    }
}

// MARK: - ModifierFlags Helper

extension ModifierFlags {
    init(from cgFlags: CGEventFlags) {
        var flags = ModifierFlags()
        if cgFlags.contains(.maskCommand) { flags.insert(.command) }
        if cgFlags.contains(.maskShift) { flags.insert(.shift) }
        if cgFlags.contains(.maskControl) { flags.insert(.control) }
        if cgFlags.contains(.maskAlternate) { flags.insert(.option) }
        self = flags
    }
    
    /// Check if this set is a subset of another set
    func isSubset(of other: ModifierFlags) -> Bool {
        return self.intersection(other) == self
    }
}

// MARK: - Event Helper Extensions

extension CGEvent {
    
    /// Get the character from keyboard event
    var characters: String? {
        guard let nsEvent = NSEvent(cgEvent: self) else {
            return nil
        }
        return nsEvent.characters
    }
    
    /// Get the character ignoring modifiers
    var charactersIgnoringModifiers: String? {
        guard let nsEvent = NSEvent(cgEvent: self) else {
            return nil
        }
        return nsEvent.charactersIgnoringModifiers
    }
    
    /// Get the key code
    var keyCode: UInt16 {
        return UInt16(getIntegerValueField(.keyboardEventKeycode))
    }
    
    /// Check if Shift key is pressed
    var isShiftPressed: Bool {
        return flags.contains(.maskShift)
    }
    
    /// Check if Command key is pressed
    var isCommandPressed: Bool {
        return flags.contains(.maskCommand)
    }
    
    /// Check if Control key is pressed
    var isControlPressed: Bool {
        return flags.contains(.maskControl)
    }
    
    /// Check if Option/Alt key is pressed
    var isOptionPressed: Bool {
        return flags.contains(.maskAlternate)
    }
    
    /// Check if Caps Lock is on
    var isCapsLockOn: Bool {
        return flags.contains(.maskAlphaShift)
    }
    
    /// Check if any modifier key is pressed (except Shift and Caps Lock)
    var hasOtherModifiers: Bool {
        return isCommandPressed || isControlPressed || isOptionPressed
    }
}

