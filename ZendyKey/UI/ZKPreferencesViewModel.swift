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
