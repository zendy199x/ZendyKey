//
//  ZKDebugLogger.swift
//  ZendyKey
//
//  Centralized logging utility that sends logs to Debug Window
//  With auto-cleanup to prevent log file bloat
//

import Foundation

/// Centralized debug logger that sends messages to Debug Window
class ZKDebugLogger {

    /// Shared instance
    static let shared = ZKDebugLogger()

    /// Reference to debug window controller (set by ZKAppDelegate)
    weak var debugWindowController: ZKDebugWindowController?
    
    // MARK: - Log File Properties
    
    private let logFileURL: URL
    private let maxLogFileSize: Int = 2 * 1024 * 1024  // 2MB max
    private let maxLogAge: TimeInterval = 24 * 60 * 60  // 24 hours
    private let cleanupInterval: TimeInterval = 60 * 60  // Cleanup every 1 hour
    private let queue = DispatchQueue(label: "com.zendy199x.zendykey.logger", qos: .utility)
    private var lastCleanupTime: CFAbsoluteTime = 0
    
    /// Enable file logging (default: false)
    var enableFileLogging: Bool = false

    private init() {
        // Create logs directory in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let logsDir = appSupport.appendingPathComponent("ZendyKey/Logs", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        
        self.logFileURL = logsDir.appendingPathComponent("zendykey_debug.log")
        
        // Initial cleanup
        cleanupIfNeeded()
    }

    /// Log a message to both console and debug window
    /// - Parameters:
    ///   - message: The message to log
    ///   - source: The source component (e.g., "ZKEngine", "ZKMacroManager")
    ///   - level: Log level (info, warning, error)
    func log(_ message: String, source: String = "", level: LogLevel = .info) {
        let prefix = level.emoji
        let fullMessage = source.isEmpty ? "\(prefix) \(message)" : "\(prefix) [\(source)] \(message)"

        // Always print to console for debugging
        // print(fullMessage)

        // Send to debug window if available
        if let debugWindow = debugWindowController, debugWindow.isLoggingEnabled {
            debugWindow.logEvent(fullMessage)
        }
        
        // Write to file if enabled
        if enableFileLogging {
            writeToFile(fullMessage, level: level)
            cleanupIfNeeded()
        }
    }

    /// Log an info message
    func info(_ message: String, source: String = "") {
        log(message, source: source, level: .info)
    }

    /// Log a warning message
    func warning(_ message: String, source: String = "") {
        log(message, source: source, level: .warning)
    }

    /// Log an error message
    func error(_ message: String, source: String = "") {
        log(message, source: source, level: .error)
    }

    /// Log a success message
    func success(_ message: String, source: String = "") {
        log(message, source: source, level: .success)
    }

    /// Log a debug message (only if verbose logging is enabled)
    func debug(_ message: String, source: String = "") {
        guard let debugWindow = debugWindowController, debugWindow.isVerboseLogging else {
            return
        }
        log(message, source: source, level: .debug)
    }
    
    // MARK: - File Logging
    
    /// Get all logs from file
    func getFileLogs() -> String {
        guard FileManager.default.fileExists(atPath: logFileURL.path),
              let content = try? String(contentsOf: logFileURL, encoding: .utf8) else {
            return ""
        }
        return content
    }
    
    /// Clear all logs
    func clearLogs() {
        queue.async { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: self.logFileURL)
        }
    }
    
    /// Get log file URL
    func getLogFileURL() -> URL {
        return logFileURL
    }
    
    // MARK: - Private Methods
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    private func writeToFile(_ message: String, level: LogLevel) {
        let logFileURL = self.logFileURL
        queue.async {
            let timestamp = Self.dateFormatter.string(from: Date())
            let logLine = "[\(timestamp)] [\(level.name)] \(message)\n"
            
            if let data = logLine.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logFileURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        try? fileHandle.close()
                    }
                } else {
                    try? data.write(to: logFileURL)
                }
            }
        }
    }
    
    private func cleanupIfNeeded() {
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastCleanupTime > cleanupInterval else { return }
        
        queue.async { [weak self] in
            self?.performCleanup()
        }
    }
    
    private func performCleanup() {
        lastCleanupTime = CFAbsoluteTimeGetCurrent()
        
        guard FileManager.default.fileExists(atPath: logFileURL.path) else { return }
        
        // Check file size
        if let attrs = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
           let fileSize = attrs[.size] as? Int,
           fileSize > maxLogFileSize {
            // File too large - keep last 50%
            trimLogFile()
        }
        
        // Remove logs older than 24 hours
        removeOldLogEntries()
    }
    
    private func trimLogFile() {
        guard let content = try? String(contentsOf: logFileURL, encoding: .utf8) else { return }
        
        let lines = content.components(separatedBy: "\n")
        let keepCount = lines.count / 2  // Keep 50%
        let trimmedContent = lines.suffix(keepCount).joined(separator: "\n")
        
        try? trimmedContent.write(to: logFileURL, atomically: true, encoding: .utf8)
    }
    
    private func removeOldLogEntries() {
        guard let content = try? String(contentsOf: logFileURL, encoding: .utf8) else { return }
        
        let cutoffDate = Date().addingTimeInterval(-maxLogAge)
        let lines = content.components(separatedBy: "\n")
        
        let filteredLines = lines.filter { line in
            guard let timestamp = extractTimestamp(from: line) else { return true }
            return timestamp > cutoffDate
        }
        
        if filteredLines.count < lines.count {
            let newContent = filteredLines.joined(separator: "\n")
            try? newContent.write(to: logFileURL, atomically: true, encoding: .utf8)
        }
    }
    
    private func extractTimestamp(from line: String) -> Date? {
        // Format: [2026-01-15 12:30:45.123]
        guard line.hasPrefix("["),
              let endBracket = line.firstIndex(of: "]") else { return nil }
        
        let timestampStr = String(line[line.index(after: line.startIndex)..<endBracket])
        return Self.dateFormatter.date(from: timestampStr)
    }
}

// MARK: - Log Level

enum LogLevel {
    case info
    case warning
    case error
    case success
    case debug

    var emoji: String {
        switch self {
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .success: return "✅"
        case .debug: return "🔍"
        }
    }
    
    var name: String {
        switch self {
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .success: return "SUCCESS"
        case .debug: return "DEBUG"
        }
    }
}

// MARK: - Convenience Global Functions

/// Log an info message to debug window
func logInfo(_ message: String, source: String = "") {
    ZKDebugLogger.shared.info(message, source: source)
}

/// Log a warning message to debug window
func logWarning(_ message: String, source: String = "") {
    ZKDebugLogger.shared.warning(message, source: source)
}

/// Log an error message to debug window
func logError(_ message: String, source: String = "") {
    ZKDebugLogger.shared.error(message, source: source)
}

/// Log a success message to debug window
func logSuccess(_ message: String, source: String = "") {
    ZKDebugLogger.shared.success(message, source: source)
}

/// Log a debug message to debug window (only if verbose logging is enabled)
func logDebug(_ message: String, source: String = "") {
    ZKDebugLogger.shared.debug(message, source: source)
}

/// Log an info message (alias for logInfo - for compatibility with new files)
func sharedLogInfo(_ message: String) {
    logInfo(message)
}

/// Log an error message (alias for logError - for compatibility with new files)
func sharedLogError(_ message: String) {
    logError(message)
}
