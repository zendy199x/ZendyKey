//
//  ZKStatusBarManager.swift
//  ZendyKey
//
//  Manager for Status Bar with Modern SwiftUI Popover
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
    private var cancellables = Set<AnyCancellable>()
    
    // Modern popover menu controller
    private lazy var modernMenuPopover: ZKMenuBarPopoverController = {
        let controller = ZKMenuBarPopoverController(viewModel: viewModel)
        controller.onCheckForUpdates = { [weak self] in
            self?.onCheckForUpdates?()
        }
        return controller
    }()
    
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
    
    // MARK: - Setup
    
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
        
        // Use modern SwiftUI popover
        button.action = #selector(statusBarButtonClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        // Setup observers
        setupObservers()
        
        log("✅ Status bar setup complete with modern popover")
    }
    
    private func setupObservers() {
        // Update icon when Vietnamese mode changes
        viewModel.$isVietnameseEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusIcon()
            }
            .store(in: &cancellables)
        
        // Log input method changes
        viewModel.$currentInputMethod
            .receive(on: DispatchQueue.main)
            .sink { [weak self] method in
                self?.log("📋 currentInputMethod changed to \(method.displayName)")
            }
            .store(in: &cancellables)
        
        // Log code table changes
        viewModel.$currentCodeTable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] table in
                self?.log("📋 currentCodeTable changed to \(table.displayName)")
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
    }
    
    // MARK: - Modern Popover
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        if modernMenuPopover.isShown {
            modernMenuPopover.dismissPopover()
        } else {
            modernMenuPopover.showPopover(from: sender)
        }
    }
    
    // MARK: - Status Icon
    
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
                    y: (size.height - logoSize.height) / 2,
                    width: logoSize.width,
                    height: logoSize.height
                )
                logo.draw(in: logoRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            }
            
            // Draw emoji flag at top-right corner
            let flagEmoji = isVietnamese ? "🇻🇳" : "🇬🇧"
            let flagFont = NSFont.systemFont(ofSize: 10)
            let flagAttributes: [NSAttributedString.Key: Any] = [
                .font: flagFont
            ]
            
            let flagSize = (flagEmoji as NSString).size(withAttributes: flagAttributes)
            let flagRect = NSRect(
                x: size.width - flagSize.width + 2,
                y: size.height - flagSize.height + 2,
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
    
    // MARK: - Public Methods
    
    func updateHotkeyDisplay(_ hotkey: Hotkey) {
        viewModel.updateHotkeyDisplay(hotkey)
    }
    
    func updateMenuBarIconStyle(_ style: MenuBarIconStyle) {
        menuBarIconStyle = style
        updateStatusIcon()
        log("🎨 Menu bar icon style updated to: \(style.rawValue)")
    }
    
    /// Rebuild menu is now no-op since we use dynamic popover
    func rebuildMenu() {
        // No-op: Modern popover is rebuilt each time it's shown
    }
}
