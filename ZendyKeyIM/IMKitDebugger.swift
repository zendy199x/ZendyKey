//
//  IMKitDebugger.swift
//  ZKIMMain
//
//  Helper for sending debug logs to ZendyKey app's debug window
//

import Foundation
import os.log

/// Singleton debugger for IMKit logging
class IMKitDebugger {
    static let shared = IMKitDebugger()

    private let notificationCenter = DistributedNotificationCenter.default()
    private let debugNotification = Notification.Name("ZendyKey.debugLog")
    private let osLog = OSLog(subsystem: "com.zendy199x.ZKIMMain", category: "Debug")

    private init() {}

    /// Log a message to ZendyKey app's debug window
    func log(_ message: String) {
        let userInfo: [String: Any] = [
            "message": message,
            "source": "ZKIMMain",
            "timestamp": Date().timeIntervalSince1970
        ]

        // Post on main thread to ensure delivery
        DispatchQueue.main.async {
            self.notificationCenter.post(
                name: self.debugNotification,
                object: nil,
                userInfo: userInfo
            )
        }

        // Use print() instead of NSLog/os_log to avoid privacy redaction
        // print() outputs to stderr and is not subject to macOS privacy filtering
        print("[ZKIMMain] \(message)")
    }

    /// Log with category
    func log(_ message: String, category: String) {
        log("[\(category)] \(message)")
    }
}
