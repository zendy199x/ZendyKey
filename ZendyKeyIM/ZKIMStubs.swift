//
//  ZKIMStubs.swift
//  ZendyKeyIM
//
//  Stub classes for ZendyKeyIM that don't need full UI components
//

import Foundation

/// Stub for ZKDebugWindowController - not needed in Input Method
/// ZKDebugLogger references this, so we provide a minimal stub
class ZKDebugWindowController {
    var isLoggingEnabled: Bool { return false }
    var isVerboseLogging: Bool { return false }
    
    func logEvent(_ message: String) {
        // No-op for Input Method - use NSLog instead
        #if DEBUG
        NSLog("[ZKIMLog] %@", message)
        #endif
    }
}
