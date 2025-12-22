//
//  ZKInputSourceSwitcher.swift
//  ZendyKey
//
//  Utility to switch between input sources programmatically
//

import Carbon
import Cocoa

class ZKInputSourceSwitcher {
    
    static let shared = ZKInputSourceSwitcher()
    
    /// ZKIMMain bundle identifier
    static let ZKIMMainBundleId = "com.zendy199x.inputmethod.ZendyKey"

    /// ABC (US English) input source bundle identifier
    static let abcBundleId = "com.apple.keyboardlayout.all"

    // MARK: - Switch Input Source

    /// Toggle between ZendyKey and ABC input sources
    /// - If currently using ZendyKey → switch to ABC (or first non-ZendyKey source)
    /// - If currently using other source → switch to ZendyKey
    /// - Returns: true if successfully switched, false otherwise
    @discardableResult
    func toggleZendyKey() -> Bool {
        let currentId = getCurrentInputSourceId()
        let isUsingZendyKey = (currentId == Self.ZKIMMainBundleId)

        if isUsingZendyKey {
            // Currently using ZendyKey → switch to ABC or fallback to first non-ZendyKey source
            // Try ABC first
            if selectInputSource(bundleId: Self.abcBundleId) {
                return true
            }

            // ABC not available, find first non-ZendyKey input source
            let sources = getEnabledInputSources()
            if let firstNonZendyKey = sources.first(where: { $0.bundleId != Self.ZKIMMainBundleId }) {
                return selectInputSource(bundleId: firstNonZendyKey.bundleId)
            }

            return false
        } else {
            // Currently using other source → switch to ZendyKey
            return selectInputSource(bundleId: Self.ZKIMMainBundleId)
        }
    }

    /// Switch to ZKIMMain input method
    /// - Returns: true if successfully switched, false otherwise
    @discardableResult
    func switchToZendyKey() -> Bool {
        return selectInputSource(bundleId: Self.ZKIMMainBundleId)
    }
    
    /// Switch to a specific input source by bundle identifier
    /// - Parameter bundleId: The bundle identifier of the input source
    /// - Returns: true if successfully switched, false otherwise
    func selectInputSource(bundleId: String) -> Bool {
        let filter: [String: Any] = [
            kTISPropertyBundleID as String: bundleId
        ]

        guard let sourceList = TISCreateInputSourceList(filter as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource],
              let source = sourceList.first else {
            return false
        }

        let result = TISSelectInputSource(source)
        return result == noErr
    }

    /// Get currently selected input source bundle ID
    func getCurrentInputSourceId() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        
        if let bundleId = TISGetInputSourceProperty(source, kTISPropertyBundleID) {
            return Unmanaged<CFString>.fromOpaque(bundleId).takeUnretainedValue() as String
        }
        
        return nil
    }
    
    /// Check if ZKIMMain is currently active
    var isZendyKeyActive: Bool {
        return getCurrentInputSourceId() == Self.ZKIMMainBundleId
    }
    
    /// Check if ZKIMMain is installed (available in input sources list)
    var isZendyKeyInstalled: Bool {
        let filter: [String: Any] = [
            kTISPropertyBundleID as String: Self.ZKIMMainBundleId
        ]
        
        guard let sourceList = TISCreateInputSourceList(filter as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource] else {
            return false
        }
        
        return !sourceList.isEmpty
    }
    
    /// Get list of all enabled keyboard input sources
    func getEnabledInputSources() -> [(bundleId: String, name: String)] {
        var result: [(bundleId: String, name: String)] = []
        
        // Get all enabled input sources
        let filter: [String: Any] = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsEnabled as String: true
        ]
        
        guard let sourceList = TISCreateInputSourceList(filter as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource] else {
            return result
        }
        
        for source in sourceList {
            var bundleId = ""
            var name = ""
            
            if let bundleIdRef = TISGetInputSourceProperty(source, kTISPropertyBundleID) {
                bundleId = Unmanaged<CFString>.fromOpaque(bundleIdRef).takeUnretainedValue() as String
            }
            
            if let nameRef = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
                name = Unmanaged<CFString>.fromOpaque(nameRef).takeUnretainedValue() as String
            }
            
            if !bundleId.isEmpty {
                result.append((bundleId: bundleId, name: name))
            }
        }
        
        return result
    }
}
