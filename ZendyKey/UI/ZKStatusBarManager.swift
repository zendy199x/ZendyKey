//
//  ZKStatusBarManager.swift
//  ZendyKey
//
//  Manager for SwiftUI Status Bar
//

import SwiftUI
import Cocoa
import Combine

class ZKStatusBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    let viewModel: ZKStatusBarViewModel
    private var menuBarIconStyle: MenuBarIconStyle = .x
    weak var debugWindowController: ZKDebugWindowController?
    var onCheckForUpdates: (() -> Void)?
    
    init(keyboardHandler: ZKKeyboardEventHandler?, eventTapManager: ZKEventTapManager?) {
        self.viewModel = ZKStatusBarViewModel(
            keyboardHandler: keyboardHandler,
            eventTapManager: eventTapManager
        )
        // Load icon style from preferences
        self.menuBarIconStyle = ZKSharedSettings.shared.loadPreferences().menuBarIconStyle
    }
    
    private func log(_ message: String) {
        debugWindowController?.logEvent(message)
    }
    
    func setupStatusBar() {
        // Connect viewModel's debug callback to our debugWindowController
        viewModel.debugLogCallback = { [weak self] message in
            self?.debugWindowController?.logEvent(message)
        }
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else {
            log("❌ Failed to create status bar button")
            return
        }
        
        // Set initial icon
        updateStatusIcon()
        
        // Create traditional NSMenu instead of popover
        let menu = createMenu()
        statusItem?.menu = menu
        
        // Observe changes to update icon and menu
        viewModel.$isVietnameseEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusIcon()
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        viewModel.$currentInputMethod
            .receive(on: DispatchQueue.main)
            .sink { [weak self] method in
                self?.log("📋 currentInputMethod changed to \(method.displayName)")
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        viewModel.$currentCodeTable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] table in
                self?.log("📋 currentCodeTable changed to \(table.displayName)")
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        // Observe hotkey changes to rebuild menu
        viewModel.$hotkeyKeyEquivalent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.log("🔑 Hotkey changed, rebuilding menu")
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
        
        viewModel.$hotkeyModifiers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.log("🔑 Hotkey modifiers changed, rebuilding menu")
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
        
        // Observe update status changes
        viewModel.$updateStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUpdateMenuItem()
            }
            .store(in: &cancellables)
        
        // Observe Input Source changes (auto-update icon for non-Latin keyboards)
        NotificationCenter.default.publisher(for: .zkInputSourceChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.log("📍 Input source changed - updating status icon")
                self?.updateStatusIcon()
            }
            .store(in: &cancellables)
        
        log("✅ Status bar setup complete")
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        // Header with logo, app info, and toggle switch (inspired by GoNhanh)
        let headerItem = NSMenuItem()
        headerItem.view = createHeaderView()
        headerItem.tag = 0
        menu.addItem(headerItem)
        menu.addItem(.separator())
        
        // Toggle Vietnamese
        // For modifier-only hotkeys, show the hotkey in the title instead of using keyEquivalent
        let prefs = ZKSharedSettings.shared.loadPreferences()
        let isModifierOnly = prefs.toggleHotkey.isModifierOnly
        
        let toggleTitle: String
        if isModifierOnly {
            // Show hotkey in title for modifier-only hotkeys (e.g., "Bật Tiếng Việt (⌃⇧)")
            let baseTitle = viewModel.isVietnameseEnabled ? "Tắt Tiếng Việt" : "Bật Tiếng Việt"
            toggleTitle = "\(baseTitle) (\(viewModel.hotkeyDisplay))"
        } else {
            toggleTitle = viewModel.isVietnameseEnabled ? "Tắt Tiếng Việt" : "Bật Tiếng Việt"
        }
        
        let toggleItem = menu.addItem(
            withTitle: toggleTitle,
            action: #selector(toggleVietnamese),
            keyEquivalent: isModifierOnly ? "" : String(viewModel.hotkeyKeyEquivalent.character)
        )
        toggleItem.target = self
        if !isModifierOnly {
            toggleItem.keyEquivalentModifierMask = convertToNSEventModifiers(viewModel.hotkeyModifiers)
        }
        // Use icon instead of checkmark state - aligns with other icons
        toggleItem.state = .off
        toggleItem.tag = 1
        toggleItem.image = NSImage(systemSymbolName: viewModel.isVietnameseEnabled ? "checkmark.circle.fill" : "circle", accessibilityDescription: nil)
        
        menu.addItem(.separator())
        
        // Input Method submenu
        let inputMethodMenu = NSMenu()
        for method in InputMethod.allCases {
            let item = inputMethodMenu.addItem(
                withTitle: method.displayName,
                action: #selector(selectInputMethod(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = method.rawValue
            item.state = (method == viewModel.currentInputMethod) ? .on : .off
        }
        
        let inputMethodItem = menu.addItem(
            withTitle: "Kiểu gõ",
            action: nil,
            keyEquivalent: ""
        )
        inputMethodItem.submenu = inputMethodMenu
        inputMethodItem.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
        
        // Code Table submenu
        let codeTableMenu = NSMenu()
        for table in CodeTable.allCases {
            let item = codeTableMenu.addItem(
                withTitle: table.displayName,
                action: #selector(selectCodeTable(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = table.rawValue
            item.state = (table == viewModel.currentCodeTable) ? .on : .off
        }
        
        let codeTableItem = menu.addItem(
            withTitle: "Bảng mã",
            action: nil,
            keyEquivalent: ""
        )
        codeTableItem.submenu = codeTableMenu
        codeTableItem.image = NSImage(systemSymbolName: "character.textbox", accessibilityDescription: nil)
        
        menu.addItem(.separator())
        
        // Advanced Tools
        let macroItem = menu.addItem(
            withTitle: "Quản lý Macro...",
            action: #selector(openMacroManagement),
            keyEquivalent: ""
        )
        macroItem.target = self
        macroItem.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: nil)
        
        let convertItem = menu.addItem(
            withTitle: "Công cụ chuyển đổi...",
            action: #selector(openZKConvertTool),
            keyEquivalent: ""
        )
        convertItem.target = self
        convertItem.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)
        
        menu.addItem(.separator())
        
        // Check for Updates - with dynamic status
        let updateTitle = getUpdateMenuTitle()
        let updateItem = menu.addItem(
            withTitle: updateTitle,
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        updateItem.tag = 100 // Tag for update item
        updateItem.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        
        menu.addItem(.separator())
        
        // Preferences
        let prefsItem = menu.addItem(
            withTitle: "Bảng điều khiển...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        prefsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        
        menu.addItem(.separator())
        
        // Version info (disabled, not clickable)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let versionItem = menu.addItem(
            withTitle: "ZendyKey v\(version)",
            action: nil,
            keyEquivalent: ""
        )
        versionItem.isEnabled = false
        versionItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        
        menu.addItem(.separator())
        
        // Quit
        let quitItem = menu.addItem(
            withTitle: "Thoát ZendyKey",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        
        return menu
    }
    
    private func updateMenu() {
        guard let menu = statusItem?.menu else {
            log("⚠️ updateMenu: menu is nil!")
            return
        }
        
        log("📋 updateMenu: currentInputMethod=\(viewModel.currentInputMethod.displayName)")
        
        // Update header view (tag 0)
        if let headerItem = menu.item(withTag: 0) {
            headerItem.view = createHeaderView()
        }
        
        // Update toggle item
        if let toggleItem = menu.item(withTag: 1) {
            let prefs = ZKSharedSettings.shared.loadPreferences()
            let isModifierOnly = prefs.toggleHotkey.isModifierOnly
            
            let baseTitle = viewModel.isVietnameseEnabled ? "Tắt Tiếng Việt" : "Bật Tiếng Việt"
            if isModifierOnly {
                toggleItem.title = "\(baseTitle) (\(viewModel.hotkeyDisplay))"
            } else {
                toggleItem.title = baseTitle
            }
            // Use icon instead of checkmark state - aligns with other icons
            toggleItem.state = .off
            toggleItem.image = NSImage(systemSymbolName: viewModel.isVietnameseEnabled ? "checkmark.circle.fill" : "circle", accessibilityDescription: nil)
        }
        
        // Update input method submenu
        if let inputMethodItem = menu.item(withTitle: "Kiểu gõ"),
           let submenu = inputMethodItem.submenu {
            for method in InputMethod.allCases {
                if let item = submenu.item(withTag: method.rawValue) {
                    let shouldBeOn = (method == viewModel.currentInputMethod)
                    item.state = shouldBeOn ? .on : .off
                }
            }
        }
        
        // Update code table submenu
        if let codeTableItem = menu.item(withTitle: "Bảng mã"),
           let submenu = codeTableItem.submenu {
            for table in CodeTable.allCases {
                if let item = submenu.item(withTag: table.rawValue) {
                    item.state = (table == viewModel.currentCodeTable) ? .on : .off
                }
            }
        }
    }
    
    @objc private func toggleVietnamese() {
        viewModel.toggleVietnamese()
    }
    
    @objc private func selectInputMethod(_ sender: NSMenuItem) {
        log("📋 selectInputMethod: tag=\(sender.tag), title=\(sender.title)")
        
        guard let method = InputMethod(rawValue: sender.tag) else {
            log("⚠️ selectInputMethod: Invalid tag \(sender.tag)")
            return
        }
        
        viewModel.selectInputMethod(method)
        
        // Update menu item states immediately (synchronously)
        if let submenu = sender.menu {
            for item in submenu.items {
                item.state = (item.tag == method.rawValue) ? .on : .off
            }
            log("✅ Updated submenu items directly")
        }
    }
    
    @objc private func selectCodeTable(_ sender: NSMenuItem) {
        guard let table = CodeTable(rawValue: sender.tag) else { return }
        
        log("📋 selectCodeTable: tag=\(sender.tag), title=\(sender.title)")
        
        viewModel.selectCodeTable(table)
        
        // Update menu item states immediately (synchronously)
        if let submenu = sender.menu {
            for item in submenu.items {
                item.state = (item.tag == table.rawValue) ? .on : .off
            }
        }
    }
    
    @objc private func openPreferences() {
        viewModel.openPreferences()
    }
    
    @objc private func openMacroManagement() {
        viewModel.openMacroManagement()
    }
    
    @objc private func openZKConvertTool() {
        viewModel.openZKConvertTool()
    }
    
    @objc private func checkForUpdates() {
        onCheckForUpdates?()
    }
    
    @objc private func quit() {
        viewModel.quit()
    }
    
    private func convertToNSEventModifiers(_ modifiers: EventModifiers) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if modifiers.contains(.command) { flags.insert(.command) }
        if modifiers.contains(.control) { flags.insert(.control) }
        if modifiers.contains(.option) { flags.insert(.option) }
        if modifiers.contains(.shift) { flags.insert(.shift) }
        return flags
    }
    
    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }
        
        let observer = ZKInputSourceObserver.shared
        
        if observer.isAllowedInputSource {
            // ABC/Latin keyboard: show logo + emoji flag (🇻🇳/🇬🇧)
            button.image = createLogoWithFlagIcon()
        } else {
            // Non-Latin keyboard (Japanese/Korean/Chinese): show character (あ/中/한)
            button.image = createInputSourceIcon(char: observer.currentDisplayChar)
        }
        button.title = ""
    }
    
    /// Create logo + emoji flag icon for Latin keyboards
    private func createLogoWithFlagIcon() -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let isVietnamese = viewModel.isVietnameseEnabled
        
        let compositeImage = NSImage(size: size, flipped: false) { rect in
            // Draw the main logo (scaled to fit with some padding for the flag)
            if let logo = NSImage(named: "ZendyKeyLogo") {
                let logoSize = NSSize(width: 16, height: 16)
                let logoRect = NSRect(
                    x: (size.width - logoSize.width) / 2 - 1,
                    y: (size.height - logoSize.height) / 2 + 2,
                    width: logoSize.width,
                    height: logoSize.height
                )
                logo.draw(in: logoRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            }
            
            // Draw emoji flag at bottom-right corner
            let flagEmoji = isVietnamese ? "🇻🇳" : "🇬🇧"
            let flagFont = NSFont.systemFont(ofSize: 8)
            let flagAttributes: [NSAttributedString.Key: Any] = [
                .font: flagFont
            ]
            
            let flagSize = (flagEmoji as NSString).size(withAttributes: flagAttributes)
            let flagRect = NSRect(
                x: size.width - flagSize.width - 1,
                y: -1,
                width: flagSize.width,
                height: flagSize.height
            )
            (flagEmoji as NSString).draw(in: flagRect, withAttributes: flagAttributes)
            
            return true
        }
        
        // Not using template so we can show colored emoji
        compositeImage.isTemplate = false
        return compositeImage
    }
    
    /// Create input source icon for non-Latin keyboards (あ/中/한)
    /// Uses template image for automatic light/dark mode support
    private func createInputSourceIcon(char: String) -> NSImage {
        let width: CGFloat = 22
        let height: CGFloat = 16
        let image = NSImage(size: NSSize(width: width, height: height))
        
        image.lockFocus()
        
        // Draw rounded rect background (black for template)
        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
        NSColor.black.setFill()
        path.fill()
        
        // Cut out text as transparent
        let font = NSFont.systemFont(ofSize: 12, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
        let textSize = char.size(withAttributes: attrs)
        let textRect = NSRect(
            x: (width - textSize.width) / 2,
            y: (height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        NSGraphicsContext.current?.compositingOperation = .destinationOut
        char.draw(in: textRect, withAttributes: attrs)
        
        image.unlockFocus()
        
        // Template image: macOS auto-adjusts color for light/dark menu bar
        image.isTemplate = true
        return image
    }
    
    func updateHotkeyDisplay(_ hotkey: Hotkey) {
        viewModel.updateHotkeyDisplay(hotkey)
    }
    
    func updateMenuBarIconStyle(_ style: MenuBarIconStyle) {
        menuBarIconStyle = style
        updateStatusIcon()
        log("🎨 Menu bar icon style updated to: \(style.rawValue)")
    }
    
    /// Create premium header view with glassmorphism, gradient toggle, and micro-interactions
    private func createHeaderView() -> NSView {
        let width: CGFloat = 260
        let height: CGFloat = 60
        
        // Use SwiftUI for premium design
        let headerContent = ZKMenuBarHeaderView(
            isVietnameseEnabled: Binding(
                get: { [weak self] in self?.viewModel.isVietnameseEnabled ?? true },
                set: { [weak self] newValue in
                    self?.viewModel.setVietnameseEnabled(newValue)
                    ZKSoundManager.shared.playToggleSound(enabled: newValue)
                    self?.updateStatusIcon()
                    self?.updateMenu()
                }
            ),
            inputMethodName: viewModel.currentInputMethod.displayName,
            hotkeyDisplay: viewModel.hotkeyDisplay
        )
        
        let hostingView = NSHostingView(rootView: headerContent)
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        
        // Wrap in NSView for menu item
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        containerView.addSubview(hostingView)
        
        return containerView
    }

    
    private func rebuildMenu() {
        guard statusItem != nil else { return }
        
        log("🔄 Rebuilding menu with new hotkey")
        
        // Create new menu with updated hotkey
        let menu = createMenu()
        statusItem?.menu = menu
        
        log("✅ Menu rebuilt successfully")
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Update Status Helpers
    
    private func getUpdateMenuTitle() -> String {
        switch viewModel.updateStatus {
        case .idle: return "Kiểm tra cập nhật..."
        case .checking: return "🔄 Đang kiểm tra..."
        case .upToDate: return "✓ Đã cập nhật mới nhất"
        case .available(let version): return "⬆ Có bản cập nhật v\(version)"
        case .downloading(let progress): return "⬇ Đang tải... \(Int(progress * 100))%"
        case .error: return "⚠️ Lỗi - thử lại"
        }
    }
    
    private func updateUpdateMenuItem() {
        guard let menu = statusItem?.menu,
              let updateItem = menu.item(withTag: 100) else { return }
        updateItem.title = getUpdateMenuTitle()
    }
}
