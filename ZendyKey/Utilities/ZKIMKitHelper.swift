//
//  ZKIMKitHelper.swift
//  ZendyKey
//
//  Helper utilities for IMKit integration
//

import Foundation
import AppKit
import Carbon

/// Helper class for managing ZKIMMain Input Method
class ZKIMKitHelper {
    
    // MARK: - Singleton
    
    static let shared = ZKIMKitHelper()
    private init() {}
    
    // MARK: - Constants
    
    /// Bundle identifier for ZKIMMain
    static let ZKIMMainBundleId = "com.zendy199x.inputmethod.ZendyKey"
    
    /// Installation path for Input Methods
    static let inputMethodsPath = "~/Library/Input Methods".expandingTildeInPath
    
    /// ZKIMMain app name
    static let ZKIMMainAppName = "ZKIMMain.app"
    
    // MARK: - Installation Check
    
    /// Check if ZKIMMain is installed
    static func isZKIMMainInstalled() -> Bool {
        let path = (inputMethodsPath as NSString).appendingPathComponent(ZKIMMainAppName)
        return FileManager.default.fileExists(atPath: path)
    }
    
    /// Check if ZKIMMain is enabled in System Settings
    static func isZKIMMainEnabled() -> Bool {
        guard let inputSources = TISCreateInputSourceList(nil, true)?.takeRetainedValue() as CFArray? else {
            return false
        }
        
        let count = CFArrayGetCount(inputSources)
        for i in 0..<count {
            let source = unsafeBitCast(CFArrayGetValueAtIndex(inputSources, i), to: TISInputSource.self)
            
            if let bundleIdPtr = TISGetInputSourceProperty(source, kTISPropertyBundleID) {
                let bundleId = Unmanaged<CFString>.fromOpaque(bundleIdPtr).takeUnretainedValue() as String
                if bundleId == ZKIMMainBundleId {
                    if let enabledPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) {
                        let enabled = Unmanaged<CFBoolean>.fromOpaque(enabledPtr).takeUnretainedValue()
                        return CFBooleanGetValue(enabled)
                    }
                }
            }
        }
        
        return false
    }
    
    // MARK: - Installation
    
    /// Install ZKIMMain to ~/Library/Input Methods
    static func installZKIMMain() {
        // Get ZKIMMain from app bundle Resources
        guard let ZKIMMainSource = Bundle.main.path(forResource: "ZKIMMain", ofType: "app") else {
            showAlert(
                title: "Không tìm thấy ZKIMMain",
                message: "ZKIMMain.app không có trong bundle. Vui lòng tải phiên bản đầy đủ từ GitHub."
            )
            return
        }
        
        let destinationPath = (inputMethodsPath as NSString).appendingPathComponent(ZKIMMainAppName)
        let fileManager = FileManager.default
        
        // First, try direct copy (works if not sandboxed or has permission)
        do {
            // Create Input Methods directory if needed
            if !fileManager.fileExists(atPath: inputMethodsPath) {
                try fileManager.createDirectory(
                    atPath: inputMethodsPath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
            
            // Remove old version if exists
            if fileManager.fileExists(atPath: destinationPath) {
                try fileManager.removeItem(atPath: destinationPath)
            }
            
            // Copy new version
            try fileManager.copyItem(atPath: ZKIMMainSource, toPath: destinationPath)
            
            // Register the input source
            registerInputSource(at: destinationPath)
            
            showAlert(
                title: "Cài đặt thành công",
                message: "ZKIMMain đã được cài đặt.\n\nVui lòng vào System Settings → Keyboard → Input Sources để bật ZendyKey Vietnamese."
            )
            
            // Open Input Sources settings
            openInputSourcesSettings()
            
        } catch {
            // If direct copy fails, show ZKIMMain in Finder for manual installation
            showManualInstallInstructions(ZKIMMainSource: ZKIMMainSource)
        }
    }
    
    /// Show manual installation instructions and reveal ZKIMMain in Finder
    private static func showManualInstallInstructions(ZKIMMainSource: String) {
        // Use a loop to keep dialog open until user clicks "Đóng"
        var shouldContinue = true
        
        while shouldContinue {
            let alert = NSAlert()
            alert.messageText = "Cài đặt thủ công ZKIMMain"
            alert.informativeText = """
            Do giới hạn bảo mật, ZendyKey không thể tự động cài đặt ZKIMMain.
            
            Vui lòng làm theo các bước sau:
            1. Nhấn "Mở ZKIMMain" để hiển thị ZKIMMain.app
            2. Nhấn "Mở Input Methods" để mở thư mục đích
            3. Kéo thả ZKIMMain.app vào thư mục Input Methods
            4. Nhấn "Mở Input Sources" để thêm ZendyKey Vietnamese
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Mở ZKIMMain")
            alert.addButton(withTitle: "Mở Input Methods")
            alert.addButton(withTitle: "Mở Input Sources")
            alert.addButton(withTitle: "Đóng")
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn:
                // Reveal ZKIMMain in Finder
                NSWorkspace.shared.selectFile(ZKIMMainSource, inFileViewerRootedAtPath: "")
                
            case .alertSecondButtonReturn:
                // Open Input Methods folder (create if needed)
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: inputMethodsPath) {
                    try? fileManager.createDirectory(
                        atPath: inputMethodsPath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
                NSWorkspace.shared.open(URL(fileURLWithPath: inputMethodsPath))
                
            case .alertThirdButtonReturn:
                // Open System Settings > Keyboard > Input Sources
                openInputSourcesSettings()
                
            default:
                // "Đóng" button - exit the loop
                shouldContinue = false
            }
        }
    }
    
    /// Uninstall ZKIMMain
    static func uninstallZKIMMain() {
        let path = (inputMethodsPath as NSString).appendingPathComponent(ZKIMMainAppName)
        
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }
        
        do {
            try FileManager.default.removeItem(atPath: path)
            
            showAlert(
                title: "Gỡ cài đặt thành công",
                message: "ZKIMMain đã được gỡ bỏ."
            )
        } catch {
            showAlert(
                title: "Lỗi",
                message: "Không thể gỡ ZKIMMain: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Input Source Registration
    
    /// Register input source with the system
    private static func registerInputSource(at path: String) {
        let url = URL(fileURLWithPath: path) as CFURL
        TISRegisterInputSource(url)
    }
    
    /// Enable ZKIMMain input source
    static func enableZKIMMain() {
        guard let inputSources = TISCreateInputSourceList(nil, true)?.takeRetainedValue() as CFArray? else {
            return
        }
        
        let count = CFArrayGetCount(inputSources)
        for i in 0..<count {
            let source = unsafeBitCast(CFArrayGetValueAtIndex(inputSources, i), to: TISInputSource.self)
            
            if let bundleIdPtr = TISGetInputSourceProperty(source, kTISPropertyBundleID) {
                let bundleId = Unmanaged<CFString>.fromOpaque(bundleIdPtr).takeUnretainedValue() as String
                if bundleId == ZKIMMainBundleId {
                    TISEnableInputSource(source)
                    return
                }
            }
        }
    }
    
    /// Select ZKIMMain as current input source
    static func selectZKIMMain() {
        guard let inputSources = TISCreateInputSourceList(nil, true)?.takeRetainedValue() as CFArray? else {
            return
        }
        
        let count = CFArrayGetCount(inputSources)
        for i in 0..<count {
            let source = unsafeBitCast(CFArrayGetValueAtIndex(inputSources, i), to: TISInputSource.self)
            
            if let bundleIdPtr = TISGetInputSourceProperty(source, kTISPropertyBundleID) {
                let bundleId = Unmanaged<CFString>.fromOpaque(bundleIdPtr).takeUnretainedValue() as String
                if bundleId == ZKIMMainBundleId {
                    TISSelectInputSource(source)
                    return
                }
            }
        }
    }
    
    // MARK: - Open System Settings
    
    /// Open Keyboard Input Sources in System Settings
    static func openInputSourcesSettings() {
        if #available(macOS 13.0, *) {
            // macOS Ventura and later
            if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension?InputSources") {
                NSWorkspace.shared.open(url)
            }
        } else {
            // Older macOS
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?InputSources") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    // MARK: - Helpers
    
    private static func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

// MARK: - String Extension

extension String {
    var expandingTildeInPath: String {
        return (self as NSString).expandingTildeInPath
    }
}
