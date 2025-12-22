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

    init() {
        // Load from ZKSharedSettings (App Group UserDefaults)
        self.preferences = ZKSharedSettings.shared.loadPreferences()
    }

    func save() {
        // Save to ZKSharedSettings (App Group UserDefaults)
        ZKSharedSettings.shared.savePreferences(preferences)

        // Apply launch at login setting
        setZKLaunchAtLogin(preferences.startAtLogin)
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
