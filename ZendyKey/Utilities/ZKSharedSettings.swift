//
//  ZKSharedSettings.swift
//  ZendyKey
//
//  Shared settings between ZendyKey (menu bar) and ZKIMMain (Input Method)
//  Uses App Group for cross-app communication
//

import Foundation

/// App Group identifier for sharing data between ZendyKey and ZKIMMain
let kZendyKeyAppGroup = "group.com.zendy199x.inputmethod.ZendyKey"

/// Keys for shared settings
enum ZKSharedSettingsKey: String {
    // Hotkey settings
    case toggleHotkeyCode = "ZendyKey.toggleHotkeyCode"
    case toggleHotkeyModifiers = "ZendyKey.toggleHotkeyModifiers"
    case toggleHotkeyIsModifierOnly = "ZendyKey.toggleHotkeyIsModifierOnly"
    case undoTypingEnabled = "ZendyKey.undoTypingEnabled"
    case beepOnToggle = "ZendyKey.beepOnToggle"
    case beepVolume = "ZendyKey.beepVolume"

    // Input settings
    case inputMethod = "ZendyKey.inputMethod"
    case codeTable = "ZendyKey.codeTable"
    case modernStyle = "ZendyKey.modernStyle"
    case spellCheckEnabled = "ZendyKey.spellCheckEnabled"
    case fixAutocomplete = "ZendyKey.fixAutocomplete"
    case rememberCodeTable = "ZendyKey.rememberCodeTable"

    // Advanced settings
    case quickTelexEnabled = "ZendyKey.quickTelexEnabled"
    case quickStartConsonantEnabled = "ZendyKey.quickStartConsonantEnabled"
    case quickEndConsonantEnabled = "ZendyKey.quickEndConsonantEnabled"
    case upperCaseFirstChar = "ZendyKey.upperCaseFirstChar"
    case restoreIfWrongSpelling = "ZendyKey.restoreIfWrongSpelling"
    case allowConsonantZFWJ = "ZendyKey.allowConsonantZFWJ"
    case freeMarkEnabled = "ZendyKey.freeMarkEnabled"
    case tempOffSpellingEnabled = "ZendyKey.tempOffSpellingEnabled"
    case tempOffEngineEnabled = "ZendyKey.tempOffEngineEnabled"

    // Restore key settings
    case restoreOnEscape = "ZendyKey.restoreOnEscape"
    case restoreKey = "ZendyKey.restoreKey"

    // Pause key settings
    case pauseKeyEnabled = "ZendyKey.pauseKeyEnabled"
    case pauseKey = "ZendyKey.pauseKey"
    case pauseKeyName = "ZendyKey.pauseKeyName"

    // Macro settings
    case macroEnabled = "ZendyKey.macroEnabled"
    case macroInEnglishMode = "ZendyKey.macroInEnglishMode"
    case autoCapsMacro = "ZendyKey.autoCapsMacro"
    case macros = "ZendyKey.macros"

    // Smart switch settings
    case smartSwitchEnabled = "ZendyKey.smartSwitchEnabled"
    case detectOverlayApps = "ZendyKey.detectOverlayApps"

    // Compatibility settings
    case sendKeyStepByStep = "ZendyKey.sendKeyStepByStep"
    case sendKeyStepByStepApps = "ZendyKey.sendKeyStepByStepApps"
    case fixChromiumBrowser = "ZendyKey.fixChromiumBrowser"
    case performLayoutCompat = "ZendyKey.performLayoutCompat"
    
    // Per-app settings
    case perAppModeEnabled = "ZendyKey.perAppModeEnabled"
    case rememberCodeTablePerApp = "ZendyKey.rememberCodeTablePerApp"
    case preserveVietnameseModeWithOtherLanguage = "ZendyKey.preserveVietnameseModeWithOtherLanguage"

    // Debug settings
    case debugModeEnabled = "ZendyKey.debugModeEnabled"

    // IMKit settings
    case imkitEnabled = "ZendyKey.imkitEnabled"
    case imkitUseMarkedText = "ZendyKey.imkitUseMarkedText"
    case switchToZendyKeyHotkeyCode = "ZendyKey.switchToZendyKeyHotkeyCode"
    case switchToZendyKeyHotkeyModifiers = "ZendyKey.switchToZendyKeyHotkeyModifiers"
    case switchToZendyKeyHotkeyIsModifierOnly = "ZendyKey.switchToZendyKeyHotkeyIsModifierOnly"

    // UI settings
    case showDockIcon = "ZendyKey.showDockIcon"
    case startAtLogin = "ZendyKey.startAtLogin"
    case menuBarIconStyle = "ZendyKey.menuBarIconStyle"
    case useVietnameseMenubarIcon = "ZendyKey.useVietnameseMenubarIcon"
    case menuBarIconSize = "ZendyKey.menuBarIconSize"

    // Excluded apps
    case excludedApps = "ZendyKey.excludedApps"

    // Input Source Management
    case inputSourceConfig = "ZendyKey.inputSourceConfig"
}

/// Manager for shared settings between ZendyKey and ZKIMMain
class ZKSharedSettings {
    
    // MARK: - Singleton
    
    static let shared = ZKSharedSettings()
    
    // MARK: - Properties
    
    /// Shared UserDefaults using App Group
    private let sharedDefaults: UserDefaults?
    
    /// Local UserDefaults (fallback)
    private let localDefaults = UserDefaults.standard

    /// Whether App Group is available
    var isAppGroupAvailable: Bool {
        return sharedDefaults != nil
    }

    /// Flag to prevent notification spam during batch updates
    private var isBatchUpdating: Bool = false
    
    // MARK: - Initialization

    private init() {
        // Try to use App Group UserDefaults
        sharedDefaults = UserDefaults(suiteName: kZendyKeyAppGroup)

        // Register default values
        registerDefaults()

        // Restore settings from backup if App Group is empty
        restoreFromBackupIfNeeded()
    }

    /// Register default values for settings
    private func registerDefaults() {
        let defaultValues: [String: Any] = [
            ZKSharedSettingsKey.inputMethod.rawValue: InputMethod.telex.rawValue,
            ZKSharedSettingsKey.codeTable.rawValue: CodeTable.unicode.rawValue,
            ZKSharedSettingsKey.modernStyle.rawValue: false,
            ZKSharedSettingsKey.spellCheckEnabled.rawValue: false,
            ZKSharedSettingsKey.quickTelexEnabled.rawValue: true,
            ZKSharedSettingsKey.restoreIfWrongSpelling.rawValue: true,
            ZKSharedSettingsKey.freeMarkEnabled.rawValue: false,
            ZKSharedSettingsKey.imkitUseMarkedText.rawValue: false,
            ZKSharedSettingsKey.fixAutocomplete.rawValue: true
        ]

        defaults.register(defaults: defaultValues)
    }

    /// Restore settings from UserDefaults.standard backup if App Group is empty
    private func restoreFromBackupIfNeeded() {
        // Only restore if we're using App Group
        guard let shared = sharedDefaults else { return }

        // Check if App Group has settings (check a key that should always exist)
        let hasSettings = shared.object(forKey: ZKSharedSettingsKey.inputMethod.rawValue) != nil

        // If App Group is empty but standard defaults has backup, restore it
        if !hasSettings {
            let hasBackup = localDefaults.object(forKey: ZKSharedSettingsKey.inputMethod.rawValue) != nil

            if hasBackup {
                logInfo("Restoring from backup...", source: "ZKSharedSettings")

                // Restore all settings from standard defaults to App Group
                for key in getAllSettingsKeys() {
                    if let value = localDefaults.object(forKey: key) {
                        shared.set(value, forKey: key)
                    }
                }

                shared.synchronize()
                logSuccess("Restored from backup successfully", source: "ZKSharedSettings")
            }
        }
    }

    /// Get all settings keys for backup/restore
    private func getAllSettingsKeys() -> [String] {
        return [
            ZKSharedSettingsKey.toggleHotkeyCode.rawValue,
            ZKSharedSettingsKey.toggleHotkeyModifiers.rawValue,
            ZKSharedSettingsKey.toggleHotkeyIsModifierOnly.rawValue,
            ZKSharedSettingsKey.undoTypingEnabled.rawValue,
            ZKSharedSettingsKey.beepOnToggle.rawValue,
            ZKSharedSettingsKey.inputMethod.rawValue,
            ZKSharedSettingsKey.codeTable.rawValue,
            ZKSharedSettingsKey.modernStyle.rawValue,
            ZKSharedSettingsKey.spellCheckEnabled.rawValue,
            ZKSharedSettingsKey.fixAutocomplete.rawValue,
            ZKSharedSettingsKey.quickTelexEnabled.rawValue,
            ZKSharedSettingsKey.quickStartConsonantEnabled.rawValue,
            ZKSharedSettingsKey.quickEndConsonantEnabled.rawValue,
            ZKSharedSettingsKey.upperCaseFirstChar.rawValue,
            ZKSharedSettingsKey.restoreIfWrongSpelling.rawValue,
            ZKSharedSettingsKey.allowConsonantZFWJ.rawValue,
            ZKSharedSettingsKey.freeMarkEnabled.rawValue,
            ZKSharedSettingsKey.tempOffSpellingEnabled.rawValue,
            ZKSharedSettingsKey.tempOffEngineEnabled.rawValue,
            ZKSharedSettingsKey.macroEnabled.rawValue,
            ZKSharedSettingsKey.macroInEnglishMode.rawValue,
            ZKSharedSettingsKey.autoCapsMacro.rawValue,
            ZKSharedSettingsKey.macros.rawValue,
            ZKSharedSettingsKey.smartSwitchEnabled.rawValue,
            ZKSharedSettingsKey.detectOverlayApps.rawValue,
            ZKSharedSettingsKey.debugModeEnabled.rawValue,
            ZKSharedSettingsKey.imkitEnabled.rawValue,
            ZKSharedSettingsKey.imkitUseMarkedText.rawValue,
            ZKSharedSettingsKey.switchToZendyKeyHotkeyCode.rawValue,
            ZKSharedSettingsKey.switchToZendyKeyHotkeyModifiers.rawValue,
            ZKSharedSettingsKey.switchToZendyKeyHotkeyIsModifierOnly.rawValue,
            ZKSharedSettingsKey.showDockIcon.rawValue,
            ZKSharedSettingsKey.startAtLogin.rawValue,
            ZKSharedSettingsKey.menuBarIconStyle.rawValue,
            ZKSharedSettingsKey.excludedApps.rawValue,
            ZKSharedSettingsKey.inputSourceConfig.rawValue
        ]
    }

    // MARK: - Defaults Access

    /// Get the appropriate UserDefaults (shared if available, local otherwise)
    private var defaults: UserDefaults {
        return sharedDefaults ?? localDefaults
    }
    
    // MARK: - Hotkey Settings

    var toggleHotkeyCode: UInt16 {
        get { UInt16(defaults.integer(forKey: ZKSharedSettingsKey.toggleHotkeyCode.rawValue)) }
        set { defaults.set(Int(newValue), forKey: ZKSharedSettingsKey.toggleHotkeyCode.rawValue) }
    }

    var toggleHotkeyModifiers: UInt {
        get { UInt(defaults.integer(forKey: ZKSharedSettingsKey.toggleHotkeyModifiers.rawValue)) }
        set { defaults.set(Int(newValue), forKey: ZKSharedSettingsKey.toggleHotkeyModifiers.rawValue) }
    }

    var toggleHotkeyIsModifierOnly: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.toggleHotkeyIsModifierOnly.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.toggleHotkeyIsModifierOnly.rawValue) }
    }

    var undoTypingEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.undoTypingEnabled.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.undoTypingEnabled.rawValue) }
    }

    var beepOnToggle: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.beepOnToggle.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.beepOnToggle.rawValue) }
    }

    var beepVolume: Double {
        get {
            let volume = defaults.double(forKey: ZKSharedSettingsKey.beepVolume.rawValue)
            return volume > 0 ? volume : 0.5  // Default to 0.5 if not set
        }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.beepVolume.rawValue) }
    }

    // MARK: - Input Method Settings

    var inputMethod: Int {
        get { defaults.integer(forKey: ZKSharedSettingsKey.inputMethod.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.inputMethod.rawValue)

            // CRITICAL: Also write directly to plist file to bypass cfprefsd caching
            // This ensures ZKIMMain will read the latest value
            writeDirectlyToPlist(key: ZKSharedSettingsKey.inputMethod.rawValue, value: newValue)

            notifySettingsChanged()
        }
    }

    var codeTable: Int {
        get { defaults.integer(forKey: ZKSharedSettingsKey.codeTable.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.codeTable.rawValue)
            notifySettingsChanged()
        }
    }

    var modernStyle: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.modernStyle.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.modernStyle.rawValue)
            notifySettingsChanged()
        }
    }

    var spellCheckEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.spellCheckEnabled.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.spellCheckEnabled.rawValue)
            notifySettingsChanged()
        }
    }

    var fixAutocomplete: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.fixAutocomplete.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.fixAutocomplete.rawValue) }
    }

    var rememberCodeTable: Bool {
        get {
            // Default to true if not explicitly set
            if defaults.object(forKey: ZKSharedSettingsKey.rememberCodeTable.rawValue) == nil {
                return true
            }
            return defaults.bool(forKey: ZKSharedSettingsKey.rememberCodeTable.rawValue)
        }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.rememberCodeTable.rawValue) }
    }

    // MARK: - Advanced Settings

    var quickTelexEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.quickTelexEnabled.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.quickTelexEnabled.rawValue)
            notifySettingsChanged()
        }
    }

    var quickStartConsonantEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.quickStartConsonantEnabled.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.quickStartConsonantEnabled.rawValue)
            notifySettingsChanged()
        }
    }

    var quickEndConsonantEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.quickEndConsonantEnabled.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.quickEndConsonantEnabled.rawValue)
            notifySettingsChanged()
        }
    }

    var upperCaseFirstChar: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.upperCaseFirstChar.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.upperCaseFirstChar.rawValue) }
    }

    var restoreIfWrongSpelling: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.restoreIfWrongSpelling.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.restoreIfWrongSpelling.rawValue)
            notifySettingsChanged()
        }
    }

    var allowConsonantZFWJ: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.allowConsonantZFWJ.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.allowConsonantZFWJ.rawValue) }
    }

    var freeMarkEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.freeMarkEnabled.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.freeMarkEnabled.rawValue)
            notifySettingsChanged()
        }
    }

    var tempOffSpellingEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.tempOffSpellingEnabled.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.tempOffSpellingEnabled.rawValue) }
    }

    var tempOffEngineEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.tempOffEngineEnabled.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.tempOffEngineEnabled.rawValue) }
    }

    // MARK: - Macro Settings

    var macroEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.macroEnabled.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.macroEnabled.rawValue)
            notifySettingsChanged()
        }
    }

    var macroInEnglishMode: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.macroInEnglishMode.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.macroInEnglishMode.rawValue) }
    }

    var autoCapsMacro: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.autoCapsMacro.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.autoCapsMacro.rawValue) }
    }

    func getMacros() -> Data? {
        return defaults.data(forKey: ZKSharedSettingsKey.macros.rawValue)
    }

    func setMacros(_ data: Data) {
        defaults.set(data, forKey: ZKSharedSettingsKey.macros.rawValue)
        notifySettingsChanged()
    }

    // MARK: - Smart Switch Settings

    var smartSwitchEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.smartSwitchEnabled.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.smartSwitchEnabled.rawValue) }
    }

    var detectOverlayApps: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.detectOverlayApps.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.detectOverlayApps.rawValue) }
    }

    // MARK: - Compatibility Settings

    var sendKeyStepByStep: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.sendKeyStepByStep.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.sendKeyStepByStep.rawValue) }
    }

    var fixChromiumBrowser: Bool {
        get {
            // Default to true if not explicitly set
            if defaults.object(forKey: ZKSharedSettingsKey.fixChromiumBrowser.rawValue) == nil {
                return true
            }
            return defaults.bool(forKey: ZKSharedSettingsKey.fixChromiumBrowser.rawValue)
        }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.fixChromiumBrowser.rawValue) }
    }

    var performLayoutCompat: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.performLayoutCompat.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.performLayoutCompat.rawValue) }
    }

    func getSendKeyStepByStepApps() -> Data? {
        return defaults.data(forKey: ZKSharedSettingsKey.sendKeyStepByStepApps.rawValue)
    }

    func setSendKeyStepByStepApps(_ data: Data) {
        defaults.set(data, forKey: ZKSharedSettingsKey.sendKeyStepByStepApps.rawValue)
    }

    // MARK: - Per-App Settings

    var perAppModeEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.perAppModeEnabled.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.perAppModeEnabled.rawValue) }
    }

    var rememberCodeTablePerApp: Bool {
        get {
            // Default to true if not explicitly set (like OpenKey)
            if defaults.object(forKey: ZKSharedSettingsKey.rememberCodeTablePerApp.rawValue) == nil {
                return true
            }
            return defaults.bool(forKey: ZKSharedSettingsKey.rememberCodeTablePerApp.rawValue)
        }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.rememberCodeTablePerApp.rawValue) }
    }

    var preserveVietnameseModeWithOtherLanguage: Bool {
        get {
            // Default to true if not explicitly set (like OpenKey vOtherLanguage)
            if defaults.object(forKey: ZKSharedSettingsKey.preserveVietnameseModeWithOtherLanguage.rawValue) == nil {
                return true
            }
            return defaults.bool(forKey: ZKSharedSettingsKey.preserveVietnameseModeWithOtherLanguage.rawValue)
        }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.preserveVietnameseModeWithOtherLanguage.rawValue) }
    }

    // MARK: - Restore Key Settings

    var restoreOnEscape: Bool {
        get {
            // Default to true if not explicitly set
            if defaults.object(forKey: ZKSharedSettingsKey.restoreOnEscape.rawValue) == nil {
                return true
            }
            return defaults.bool(forKey: ZKSharedSettingsKey.restoreOnEscape.rawValue)
        }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.restoreOnEscape.rawValue) }
    }

    var restoreKey: UInt16 {
        get {
            let value = defaults.integer(forKey: ZKSharedSettingsKey.restoreKey.rawValue)
            return value > 0 ? UInt16(value) : 53  // Default to ESC (53)
        }
        set { defaults.set(Int(newValue), forKey: ZKSharedSettingsKey.restoreKey.rawValue) }
    }

    // MARK: - Pause Key Settings

    var pauseKeyEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.pauseKeyEnabled.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.pauseKeyEnabled.rawValue) }
    }

    var pauseKey: UInt16 {
        get {
            let value = defaults.integer(forKey: ZKSharedSettingsKey.pauseKey.rawValue)
            return value > 0 ? UInt16(value) : 58  // Default to Option (58)
        }
        set { defaults.set(Int(newValue), forKey: ZKSharedSettingsKey.pauseKey.rawValue) }
    }

    var pauseKeyName: String {
        get { defaults.string(forKey: ZKSharedSettingsKey.pauseKeyName.rawValue) ?? "Option" }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.pauseKeyName.rawValue) }
    }

    // MARK: - Debug Settings

    var debugModeEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.debugModeEnabled.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.debugModeEnabled.rawValue) }
    }

    // MARK: - IMKit Settings

    var imkitEnabled: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.imkitEnabled.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.imkitEnabled.rawValue)
            notifySettingsChanged()
        }
    }

    var imkitUseMarkedText: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.imkitUseMarkedText.rawValue) }
        set {
            defaults.set(newValue, forKey: ZKSharedSettingsKey.imkitUseMarkedText.rawValue)

            // CRITICAL: Also write directly to plist file to bypass cfprefsd caching
            // This ensures ZKIMMain will read the latest value
            writeDirectlyToPlist(key: ZKSharedSettingsKey.imkitUseMarkedText.rawValue, value: newValue)

            notifySettingsChanged()
        }
    }

    var switchToZendyKeyHotkeyCode: UInt16 {
        get { UInt16(defaults.integer(forKey: ZKSharedSettingsKey.switchToZendyKeyHotkeyCode.rawValue)) }
        set { defaults.set(Int(newValue), forKey: ZKSharedSettingsKey.switchToZendyKeyHotkeyCode.rawValue) }
    }

    var switchToZendyKeyHotkeyModifiers: UInt {
        get { UInt(defaults.integer(forKey: ZKSharedSettingsKey.switchToZendyKeyHotkeyModifiers.rawValue)) }
        set { defaults.set(Int(newValue), forKey: ZKSharedSettingsKey.switchToZendyKeyHotkeyModifiers.rawValue) }
    }

    var switchToZendyKeyHotkeyIsModifierOnly: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.switchToZendyKeyHotkeyIsModifierOnly.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.switchToZendyKeyHotkeyIsModifierOnly.rawValue) }
    }

    // MARK: - UI Settings

    var showDockIcon: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.showDockIcon.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.showDockIcon.rawValue) }
    }

    var startAtLogin: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.startAtLogin.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.startAtLogin.rawValue) }
    }

    var menuBarIconStyle: String {
        get { defaults.string(forKey: ZKSharedSettingsKey.menuBarIconStyle.rawValue) ?? "X" }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.menuBarIconStyle.rawValue) }
    }

    var useVietnameseMenubarIcon: Bool {
        get { defaults.bool(forKey: ZKSharedSettingsKey.useVietnameseMenubarIcon.rawValue) }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.useVietnameseMenubarIcon.rawValue) }
    }

    var menuBarIconSize: Double {
        get {
            let size = defaults.double(forKey: ZKSharedSettingsKey.menuBarIconSize.rawValue)
            return size > 0 ? size : 18.0  // Default to 18.0 if not set
        }
        set { defaults.set(newValue, forKey: ZKSharedSettingsKey.menuBarIconSize.rawValue) }
    }

    // MARK: - Excluded Apps

    func getExcludedApps() -> Data? {
        return defaults.data(forKey: ZKSharedSettingsKey.excludedApps.rawValue)
    }

    func setExcludedApps(_ data: Data) {
        defaults.set(data, forKey: ZKSharedSettingsKey.excludedApps.rawValue)
    }

    // MARK: - Input Source Management

    func getInputSourceConfig() -> Data? {
        return defaults.data(forKey: ZKSharedSettingsKey.inputSourceConfig.rawValue)
    }

    func setInputSourceConfig(_ data: Data) {
        defaults.set(data, forKey: ZKSharedSettingsKey.inputSourceConfig.rawValue)
    }

    // MARK: - Sync

    /// Synchronize settings to disk with dual backup
    func synchronize() {
        // Save to primary storage (App Group or local)
        defaults.synchronize()

        // CRITICAL: Force flush using CFPreferences for cross-process sync
        // Use CFPreferencesSynchronize with full parameters for maximum reliability
        CFPreferencesSynchronize(
            kZendyKeyAppGroup as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )

        // CRITICAL: Also backup to UserDefaults.standard as failsafe
        // This ensures settings persist even if App Group container changes
        backupToStandardDefaults()
    }

    /// Backup all settings to UserDefaults.standard as failsafe
    private func backupToStandardDefaults() {
        // Only backup if we're using App Group (otherwise we'd create duplicate)
        guard sharedDefaults != nil else { return }

        // Backup all settings to standard UserDefaults
        for key in getAllSettingsKeys() {
            if let value = sharedDefaults?.object(forKey: key) {
                localDefaults.set(value, forKey: key)
            }
        }

        localDefaults.synchronize()
    }
    
    /// Write directly to plist file to bypass cfprefsd caching
    /// This is needed because cfprefsd doesn't always flush to disk in time for ZKIMMain to read
    private func writeDirectlyToPlist(key: String, value: Any) {
        // Skip if in batch mode - we'll write everything at once later
        guard !isBatchUpdating else { return }

        writeDirectlyToPlistInternal(key: key, value: value)
    }

    /// Internal plist write function (bypasses batch check)
    private func writeDirectlyToPlistInternal(key: String, value: Any) {
        // Get the plist file path in App Group container
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kZendyKeyAppGroup) else {
            logWarning("Cannot get App Group container URL", source: "ZKSharedSettings")
            return
        }

        let prefsURL = containerURL.appendingPathComponent("Library/Preferences/\(kZendyKeyAppGroup).plist")

        // Read existing plist or create new one
        var plistDict: [String: Any] = [:]
        if let data = try? Data(contentsOf: prefsURL),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            plistDict = dict
        }

        // Update the value
        plistDict[key] = value

        // Write back to file
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .binary, options: 0)
            try data.write(to: prefsURL)
            logSuccess("Wrote \(key)=\(value) directly to plist", source: "ZKSharedSettings")
        } catch {
            logError("Failed to write plist: \(error)", source: "ZKSharedSettings")
        }
    }

    /// Notify that settings have changed (for observers)
    private func notifySettingsChanged() {
        // Skip notification if we're in batch update mode
        // This prevents notification spam when saving multiple settings at once
        guard !isBatchUpdating else { return }

        // IMPORTANT: Synchronize BEFORE notifying!
        // This ensures ZKIMMain receives the latest values when it reloads
        defaults.synchronize()

        // CRITICAL: Force CFPreferences to flush to disk immediately
        // This prevents ZKIMMain from reading stale cached values
        // Use CFPreferencesSynchronize with full parameters for maximum reliability
        CFPreferencesSynchronize(
            kZendyKeyAppGroup as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )

        // Post notification for local observers
        NotificationCenter.default.post(
            name: .sharedSettingsDidChange,
            object: nil
        )

        // Post distributed notification for cross-app communication
        DistributedNotificationCenter.default().post(
            name: .ZendyKeySettingsDidChange,
            object: nil
        )
    }
    
    // MARK: - Load/Save Preferences Object

    /// Load all settings as a Preferences object
    func loadPreferences() -> Preferences {
        var prefs = Preferences()

        // Hotkey settings
        let hotkeyCode = toggleHotkeyCode
        let hotkeyModifiers = toggleHotkeyModifiers
        if hotkeyCode != 0 || hotkeyModifiers != 0 {
            prefs.toggleHotkey = Hotkey(
                keyCode: hotkeyCode,
                modifiers: ModifierFlags(rawValue: hotkeyModifiers),
                isModifierOnly: toggleHotkeyIsModifierOnly
            )
        }
        prefs.undoTypingEnabled = undoTypingEnabled
        prefs.beepOnToggle = beepOnToggle
        prefs.beepVolume = beepVolume

        // Input settings
        if let method = InputMethod(rawValue: inputMethod) {
            prefs.inputMethod = method
        }
        if let table = CodeTable(rawValue: codeTable) {
            prefs.codeTable = table
        }
        prefs.modernStyle = modernStyle
        prefs.spellCheckEnabled = spellCheckEnabled
        prefs.fixAutocomplete = fixAutocomplete
        prefs.rememberCodeTable = rememberCodeTable

        // Advanced settings
        prefs.quickTelexEnabled = quickTelexEnabled
        prefs.quickStartConsonantEnabled = quickStartConsonantEnabled
        prefs.quickEndConsonantEnabled = quickEndConsonantEnabled
        prefs.upperCaseFirstChar = upperCaseFirstChar
        prefs.restoreIfWrongSpelling = restoreIfWrongSpelling
        prefs.allowConsonantZFWJ = allowConsonantZFWJ
        prefs.freeMarkEnabled = freeMarkEnabled
        prefs.tempOffSpellingEnabled = tempOffSpellingEnabled
        prefs.tempOffEngineEnabled = tempOffEngineEnabled

        // Restore key settings
        prefs.restoreOnEscape = restoreOnEscape
        if let key = RestoreKey(rawValue: restoreKey) {
            prefs.restoreKey = key
        }

        // Pause key settings
        prefs.pauseKeyEnabled = pauseKeyEnabled
        prefs.pauseKey = pauseKey
        prefs.pauseKeyName = pauseKeyName

        // Macro settings
        prefs.macroEnabled = macroEnabled
        prefs.macroInEnglishMode = macroInEnglishMode
        prefs.autoCapsMacro = autoCapsMacro

        // Smart switch
        prefs.smartSwitchEnabled = smartSwitchEnabled
        prefs.detectOverlayApps = detectOverlayApps

        // Per-app settings
        prefs.perAppModeEnabled = perAppModeEnabled
        prefs.rememberCodeTablePerApp = rememberCodeTablePerApp
        prefs.preserveVietnameseModeWithOtherLanguage = preserveVietnameseModeWithOtherLanguage

        // Compatibility settings
        prefs.sendKeyStepByStep = sendKeyStepByStep
        prefs.fixChromiumBrowser = fixChromiumBrowser
        prefs.performLayoutCompat = performLayoutCompat

        // Debug
        prefs.debugModeEnabled = debugModeEnabled

        // IMKit
        prefs.imkitEnabled = imkitEnabled
        prefs.imkitUseMarkedText = imkitUseMarkedText

        // Switch to ZendyKey hotkey (optional)
        let switchHotkeyCode = switchToZendyKeyHotkeyCode
        let switchHotkeyModifiers = switchToZendyKeyHotkeyModifiers
        if switchHotkeyCode != 0 || switchHotkeyModifiers != 0 {
            prefs.switchToZendyKeyHotkey = Hotkey(
                keyCode: switchHotkeyCode,
                modifiers: ModifierFlags(rawValue: switchHotkeyModifiers),
                isModifierOnly: switchToZendyKeyHotkeyIsModifierOnly
            )
        }

        // UI settings
        prefs.showDockIcon = showDockIcon
        prefs.startAtLogin = startAtLogin
        if let style = MenuBarIconStyle(rawValue: menuBarIconStyle) {
            prefs.menuBarIconStyle = style
        }
        prefs.useVietnameseMenubarIcon = useVietnameseMenubarIcon
        prefs.menuBarIconSize = menuBarIconSize

        // Excluded apps
        if let data = getExcludedApps(),
           let apps = try? JSONDecoder().decode([ExcludedApp].self, from: data) {
            prefs.excludedApps = apps
        }

        // SendKeyStepByStep apps
        if let data = getSendKeyStepByStepApps(),
           let apps = try? JSONDecoder().decode([SendKeyStepByStepApp].self, from: data) {
            prefs.sendKeyStepByStepApps = apps
        }

        return prefs
    }

    /// Save a Preferences object to shared settings
    func savePreferences(_ prefs: Preferences) {
        // Enable batch mode to prevent notification spam
        isBatchUpdating = true
        defer {
            // Always disable batch mode when done, even if error occurs
            isBatchUpdating = false
        }

        // Hotkey settings
        toggleHotkeyCode = prefs.toggleHotkey.keyCode
        toggleHotkeyModifiers = prefs.toggleHotkey.modifiers.rawValue
        toggleHotkeyIsModifierOnly = prefs.toggleHotkey.isModifierOnly
        undoTypingEnabled = prefs.undoTypingEnabled
        beepOnToggle = prefs.beepOnToggle
        beepVolume = prefs.beepVolume

        // Input settings
        inputMethod = prefs.inputMethod.rawValue
        codeTable = prefs.codeTable.rawValue
        modernStyle = prefs.modernStyle
        spellCheckEnabled = prefs.spellCheckEnabled
        fixAutocomplete = prefs.fixAutocomplete
        rememberCodeTable = prefs.rememberCodeTable

        // Advanced settings
        quickTelexEnabled = prefs.quickTelexEnabled
        quickStartConsonantEnabled = prefs.quickStartConsonantEnabled
        quickEndConsonantEnabled = prefs.quickEndConsonantEnabled
        upperCaseFirstChar = prefs.upperCaseFirstChar
        restoreIfWrongSpelling = prefs.restoreIfWrongSpelling
        allowConsonantZFWJ = prefs.allowConsonantZFWJ
        freeMarkEnabled = prefs.freeMarkEnabled
        tempOffSpellingEnabled = prefs.tempOffSpellingEnabled
        tempOffEngineEnabled = prefs.tempOffEngineEnabled

        // Restore key settings
        restoreOnEscape = prefs.restoreOnEscape
        restoreKey = prefs.restoreKey.rawValue

        // Pause key settings
        pauseKeyEnabled = prefs.pauseKeyEnabled
        pauseKey = prefs.pauseKey
        pauseKeyName = prefs.pauseKeyName

        // Macro settings
        macroEnabled = prefs.macroEnabled
        macroInEnglishMode = prefs.macroInEnglishMode
        autoCapsMacro = prefs.autoCapsMacro

        // Smart switch
        smartSwitchEnabled = prefs.smartSwitchEnabled
        detectOverlayApps = prefs.detectOverlayApps

        // Per-app settings
        perAppModeEnabled = prefs.perAppModeEnabled
        rememberCodeTablePerApp = prefs.rememberCodeTablePerApp
        preserveVietnameseModeWithOtherLanguage = prefs.preserveVietnameseModeWithOtherLanguage

        // Compatibility settings
        sendKeyStepByStep = prefs.sendKeyStepByStep
        fixChromiumBrowser = prefs.fixChromiumBrowser
        performLayoutCompat = prefs.performLayoutCompat

        // Debug
        debugModeEnabled = prefs.debugModeEnabled

        // IMKit
        imkitEnabled = prefs.imkitEnabled
        imkitUseMarkedText = prefs.imkitUseMarkedText

        // Switch to ZendyKey hotkey (optional)
        if let switchHotkey = prefs.switchToZendyKeyHotkey {
            switchToZendyKeyHotkeyCode = switchHotkey.keyCode
            switchToZendyKeyHotkeyModifiers = switchHotkey.modifiers.rawValue
            switchToZendyKeyHotkeyIsModifierOnly = switchHotkey.isModifierOnly
        } else {
            // Clear the hotkey if nil
            switchToZendyKeyHotkeyCode = 0
            switchToZendyKeyHotkeyModifiers = 0
            switchToZendyKeyHotkeyIsModifierOnly = false
        }

        // UI settings
        showDockIcon = prefs.showDockIcon
        startAtLogin = prefs.startAtLogin
        menuBarIconStyle = prefs.menuBarIconStyle.rawValue
        useVietnameseMenubarIcon = prefs.useVietnameseMenubarIcon
        menuBarIconSize = prefs.menuBarIconSize

        // Excluded apps
        if let data = try? JSONEncoder().encode(prefs.excludedApps) {
            setExcludedApps(data)
        }

        // SendKeyStepByStep apps
        if let data = try? JSONEncoder().encode(prefs.sendKeyStepByStepApps) {
            setSendKeyStepByStepApps(data)
        }

        // Batch update is done - disable batch mode and write critical values to plist
        isBatchUpdating = false

        // CRITICAL: Write important values directly to plist to ensure ZKIMMain reads them
        // These are the values that ZKIMMain reads directly from plist file
        writeDirectlyToPlistInternal(key: ZKSharedSettingsKey.inputMethod.rawValue, value: prefs.inputMethod.rawValue)
        writeDirectlyToPlistInternal(key: ZKSharedSettingsKey.imkitUseMarkedText.rawValue, value: prefs.imkitUseMarkedText)

        // Now send ONE notification
        notifySettingsChanged()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when shared settings change (local)
    static let sharedSettingsDidChange = Notification.Name("ZendyKey.sharedSettingsDidChange")
    
    /// Posted when settings change (distributed, cross-app)
    static let ZendyKeySettingsDidChange = Notification.Name("ZendyKey.settingsDidChange")
}
