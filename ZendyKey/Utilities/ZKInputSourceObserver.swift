//
//  ZKInputSourceObserver.swift
//  ZendyKey
//
//  Observes input source changes and auto-enables/disables ZendyKey
//

import Foundation
import Carbon.HIToolbox

private let kAppleKeyLayoutPrefix = "com.apple.keylayout."

/// Input sources that show V/E icon (Latin-based keyboards)
private let allowedInputSources: Set<String> = Set([
    // ABC variants
    "ABC", "ABC-AZERTY", "ABC-India", "ABC-QWERTZ",
    // US variants
    "US", "USExtended", "USInternational-PC",
    // UK variants
    "British", "British-PC", "Australian", "Irish", "IrishExtended",
    // Canadian
    "Canadian", "Canadian-CSA", "CanadianFrench-PC",
    // Alternative layouts
    "Colemak", "Dvorak", "Dvorak-Left", "Dvorak-Right", "DVORAK-QWERTYCMD",
    // European layouts
    "German", "German-DIN-2137", "French", "French-PC", "French-numerical",
    "Spanish", "Spanish-ISO", "Italian", "Italian-Pro", "Portuguese",
    "Dutch", "Belgian", "SwissFrench", "SwissGerman", "Norwegian",
    "Swedish", "Danish", "Finnish", "Icelandic", "Polish", "Czech",
    "Hungarian", "Romanian", "Turkish", "Turkish-QWERTY-PC",
    // Vietnamese-related (when using other Vietnamese IMEs)
    "Vietnamese", "VietnameseSimpleTelex"
].map { kAppleKeyLayoutPrefix + $0 })

// MARK: - Input Source Observer

/// Observes input source changes and auto-enables/disables ZendyKey
final class ZKInputSourceObserver {
    static let shared = ZKInputSourceObserver()
    
    private var isObserving = false
    private var lastInputSourceId: String?
    
    /// Current input source display character (for menu icon)
    private(set) var currentDisplayChar: String = "V"
    
    /// Whether ZendyKey is allowed for current input source
    private(set) var isAllowedInputSource: Bool = true
    
    /// Callback when input source changes
    var onInputSourceChanged: ((Bool) -> Void)?
    
    // MARK: - Other Language Mode (OpenKey vOtherLanguage)
    
    /// Saved Vietnamese mode state before switching to non-Latin input source
    private var savedVietnameseModeBeforeNonLatin: Bool?
    
    /// Whether we're currently in a non-Latin input source
    private var wasNonLatinInputSource: Bool = false
    
    /// Callback to restore Vietnamese mode
    /// Parameters: (shouldRestoreMode: Bool, wasVietnameseModeEnabled: Bool)
    var onRestoreVietnameseMode: ((Bool) -> Void)?
    
    /// Callback to get current Vietnamese mode state
    var getCurrentVietnameseMode: (() -> Bool)?
    
    private init() {}
    
    func start() {
        guard !isObserving else { return }
        isObserving = true
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDistributedCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            inputSourceCallback,
            kTISNotifySelectedKeyboardInputSourceChanged,
            nil,
            .deliverImmediately
        )
        
        handleChange()
    }
    
    func stop() {
        guard isObserving else { return }
        isObserving = false
        
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDistributedCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(kTISNotifySelectedKeyboardInputSourceChanged),
            nil
        )
    }
    
    fileprivate func handleChange() {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return
        }
        
        let currentId = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
        
        // Skip if same as last
        guard currentId != lastInputSourceId else { return }
        lastInputSourceId = currentId
        
        // Get display character from input source
        currentDisplayChar = getDisplayChar(from: source, id: currentId)
        let isAllowed = isInputSourceAllowed(currentId)
        
        // Handle "Other Language Mode" (OpenKey vOtherLanguage feature)
        handleOtherLanguageMode(isNowAllowed: isAllowed)
        
        isAllowedInputSource = isAllowed
        
        // Notify observers
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onInputSourceChanged?(self.isAllowedInputSource)
            NotificationCenter.default.post(name: .zkInputSourceChanged, object: nil, userInfo: [
                "isAllowed": self.isAllowedInputSource,
                "displayChar": self.currentDisplayChar
            ])
        }
    }
    
    /// Handle the "Other Language Mode" feature (OpenKey vOtherLanguage)
    /// When switching FROM Latin TO non-Latin: save current Vietnamese mode
    /// When switching FROM non-Latin TO Latin: restore saved Vietnamese mode
    private func handleOtherLanguageMode(isNowAllowed: Bool) {
        let prefs = ZKSharedSettings.shared.loadPreferences()
        guard prefs.preserveVietnameseModeWithOtherLanguage else { return }
        
        let isNonLatinNow = !isNowAllowed
        let wasNonLatin = wasNonLatinInputSource
        
        // Update state
        wasNonLatinInputSource = isNonLatinNow
        
        if !wasNonLatin && isNonLatinNow {
            // Switching FROM Latin TO non-Latin: save current Vietnamese mode
            if let getCurrentMode = getCurrentVietnameseMode {
                savedVietnameseModeBeforeNonLatin = getCurrentMode()
                logDebug("🌍 Other Language Mode: Saved Vietnamese mode = \(savedVietnameseModeBeforeNonLatin ?? false)")
            }
        } else if wasNonLatin && !isNonLatinNow {
            // Switching FROM non-Latin TO Latin: restore saved Vietnamese mode
            if let savedMode = savedVietnameseModeBeforeNonLatin {
                logDebug("🌍 Other Language Mode: Restoring Vietnamese mode = \(savedMode)")
                DispatchQueue.main.async { [weak self] in
                    self?.onRestoreVietnameseMode?(savedMode)
                }
                // Clear saved state
                savedVietnameseModeBeforeNonLatin = nil
            }
        }
    }
    
    private func logDebug(_ message: String) {
        #if DEBUG
        print("[ZKInputSourceObserver] \(message)")
        #endif
    }
    
    private func isInputSourceAllowed(_ id: String) -> Bool {
        // Allow all Latin-based keyboards
        if allowedInputSources.contains(id) {
            return true
        }
        
        // Also allow any input source that starts with com.apple.keylayout and looks Latin
        if id.hasPrefix(kAppleKeyLayoutPrefix) {
            // Try to be permissive - only block known non-Latin scripts
            let layout = id.replacingOccurrences(of: kAppleKeyLayoutPrefix, with: "")
            let nonLatinPatterns = [
                "Japanese", "Kana", "Hiragana", "Katakana", "Romaji",
                "Chinese", "Pinyin", "Zhuyin", "Cangjie", "Wubi",
                "Korean", "Hangul",
                "Arabic", "Hebrew", "Cyrillic", "Greek", "Thai",
                "Hindi", "Devanagari", "Tamil", "Telugu", "Kannada",
                "Myanmar", "Khmer", "Lao", "Georgian", "Armenian"
            ]
            for pattern in nonLatinPatterns {
                if layout.contains(pattern) {
                    return false
                }
            }
            return true
        }
        
        // For non-Apple input sources, be permissive
        return true
    }
    
    private func getDisplayChar(from source: TISInputSource, id: String) -> String {
        // Get language code
        if let langsPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages),
           let langs = Unmanaged<CFArray>.fromOpaque(langsPtr).takeUnretainedValue() as? [String],
           let lang = langs.first {
            switch lang {
            // East Asian
            case "ja": return "あ"
            case "zh-Hans", "zh-Hant", "zh": return "中"
            case "ko": return "한"
            // Southeast Asian (ASEAN)
            case "th": return "ก"
            case "km": return "ក"  // Khmer/Cambodian
            case "lo": return "ກ"  // Lao
            case "my": return "က"  // Myanmar/Burmese
            // South Asian
            case "hi", "mr", "ne", "sa": return "अ"  // Hindi, Marathi, Nepali, Sanskrit
            case "bn": return "অ"  // Bengali/Bangla
            case "ta": return "அ"  // Tamil
            // Other common
            case "vi": return "V"  // Vietnamese input source = show V
            case "ru": return "Р"
            case "ar": return "ع"
            case "he": return "א"
            case "el": return "Ω"
            case "fa", "ur": return "ف"  // Persian, Urdu
            case "en": return "E"
            default: break
            }
        }
        
        // Fallback: use first char of localized name
        if let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            let name = Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
            if let first = name.first {
                return String(first).uppercased()
            }
        }
        
        return "E"
    }
}

// MARK: - C Callback

private let inputSourceCallback: CFNotificationCallback = { _, observer, _, _, _ in
    guard let observer = observer else { return }
    let instance = Unmanaged<ZKInputSourceObserver>.fromOpaque(observer).takeUnretainedValue()
    DispatchQueue.main.async {
        instance.handleChange()
    }
}

// MARK: - Notification

extension Notification.Name {
    static let zkInputSourceChanged = Notification.Name("zkInputSourceChanged")
}
