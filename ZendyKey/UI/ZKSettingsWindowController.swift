//
//  ZKSettingsWindowController.swift
//  ZendyKey
//
//  Window controller for unified Settings with Apple-style design
//

import Cocoa
import SwiftUI

@available(macOS 13.0, *)
class ZKSettingsWindowController: NSWindowController {

    convenience init(selectedSection: SettingsSection = .general, onSave: @escaping (Preferences) -> Void) {
        // Create window with modern style
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 550),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Cài đặt ZendyKey"
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.center()
        
        // Apply appearance mode
        switch AppearanceManager.shared.currentMode {
        case .system:
            window.appearance = nil
        case .dark:
            window.appearance = NSAppearance(named: .darkAqua)
        case .light:
            window.appearance = NSAppearance(named: .aqua)
        }

        self.init(window: window)

        // Create SwiftUI view with auto-save callback
        let settingsView = ZKSettingsView(
            selectedSection: selectedSection,
            onSave: onSave,
            onClose: nil
        )

        // Wrap in hosting controller
        let hostingController = NSHostingController(rootView: settingsView)
        window.contentViewController = hostingController
    }
}
