//
//  ZKPreferencesViewModel.swift
//  ZendyKey
//
//  ViewModel for Preferences
//

import SwiftUI
import Combine

import ServiceManagement

class ZKPreferencesViewModel: ObservableObject {
    @Published var preferences: Preferences
    
    private var cancellables = Set<AnyCancellable>()
    private var isSaving = false  // Prevent circular notification
    
    // Conflict auto-reset timer (10 seconds)
    private var conflictResetTimer: Timer?
    private let conflictResetDelay: TimeInterval = 10.0

    init() {
        // Load from ZKSharedSettings (App Group UserDefaults)
        self.preferences = ZKSharedSettings.shared.loadPreferences()
        
        // Listen for external settings changes (from menubar, hotkey, etc.)
        NotificationCenter.default.publisher(for: .ZendyKeySettingsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isSaving else { return }
                self.reloadPreferencesWithAnimation()
            }
            .store(in: &cancellables)
    }
    
    /// Reload preferences from storage with animation
    func reloadPreferencesWithAnimation() {
        let newPreferences = ZKSharedSettings.shared.loadPreferences()
        
        // Only update if there are actual changes
        if preferences.inputMethod != newPreferences.inputMethod ||
           preferences.codeTable != newPreferences.codeTable ||
           preferences.modernStyle != newPreferences.modernStyle ||
           preferences.spellCheckEnabled != newPreferences.spellCheckEnabled ||
           preferences.beepOnToggle != newPreferences.beepOnToggle {
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                preferences = newPreferences
            }
        }
    }

    func save() {
        isSaving = true
        defer { isSaving = false }
        
        // Save to ZKSharedSettings (App Group UserDefaults)
        ZKSharedSettings.shared.savePreferences(preferences)

        // Apply launch at login setting
        setZKLaunchAtLogin(preferences.startAtLogin)
        
        // Notify other components
        NotificationCenter.default.post(name: .ZendyKeySettingsDidChange, object: nil)
        
        // Check for conflicts and start auto-reset timer if needed
        checkAndStartConflictResetTimer()
    }
    
    // MARK: - Conflict Auto-Reset
    
    /// Called when user interacts with any of the 3 hotkey sections
    /// This restarts the 10s timer
    func userDidInteractWithHotkeySection() {
        // Cancel any existing timer
        conflictResetTimer?.invalidate()
        conflictResetTimer = nil
        
        // If there are conflicts, start the timer
        if hasConflicts() {
            conflictResetTimer = Timer.scheduledTimer(
                withTimeInterval: conflictResetDelay,
                repeats: false
            ) { [weak self] _ in
                self?.resetConflictingKeysToDefaults()
            }
        }
    }
    
    /// Check if there are any conflicts between the 3 hotkey sections
    private func hasConflicts() -> Bool {
        let pauseEnabled = preferences.pauseKeyEnabled
        let restoreEnabled = preferences.restoreOnEscape
        let tempOffEnabled = preferences.tempOffSpellingEnabled
        
        // No conflicts if less than 2 features are enabled
        let enabledCount = [pauseEnabled, restoreEnabled, tempOffEnabled].filter { $0 }.count
        guard enabledCount >= 2 else { return false }
        
        // Check pause vs restore conflict
        if pauseEnabled && restoreEnabled {
            if preferences.pauseKey == preferences.restoreKey.rawValue {
                return true
            }
        }
        
        // Check pause vs temp off conflict  
        if pauseEnabled && tempOffEnabled {
            if preferences.pauseKey == preferences.tempOffSpellingKey {
                return true
            }
        }
        
        // Check restore vs temp off conflict
        if restoreEnabled && tempOffEnabled {
            if preferences.restoreKey.rawValue == preferences.tempOffSpellingKey {
                return true
            }
        }
        
        return false
    }
    
    /// Reset conflicting keys to their default values
    private func resetConflictingKeysToDefaults() {
        guard hasConflicts() else { return }
        
        // Default values:
        // - Restore key: ESC (keyCode 53)
        // - Pause key: Control (keyCode 59)
        // - Temp off spelling: Option (keyCode 58)
        
        withAnimation(ZKAnimations.spring) {
            // Reset pause key to Control (59)
            preferences.pauseKey = 59
            preferences.pauseKeyName = "Control"
            
            // Reset restore key to ESC
            preferences.restoreKey = .esc
            
            // Reset temp off spelling to Option (58)
            preferences.tempOffSpellingKey = 58
        }
        
        // Save the reset preferences
        save()
        
        // Cancel timer
        conflictResetTimer?.invalidate()
        conflictResetTimer = nil
    }
    
    private func checkAndStartConflictResetTimer() {
        // Cancel any existing timer
        conflictResetTimer?.invalidate()
        conflictResetTimer = nil
        
        // If there are conflicts, start the timer
        if hasConflicts() {
            conflictResetTimer = Timer.scheduledTimer(
                withTimeInterval: conflictResetDelay,
                repeats: false
            ) { [weak self] _ in
                self?.resetConflictingKeysToDefaults()
            }
        }
    }

    private func setZKLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                
            }
        } else {
            SMLoginItemSetEnabled("group.com.zendy199x.inputmethod.ZendyKey.debug" as CFString, enabled)
        }
    }
}
