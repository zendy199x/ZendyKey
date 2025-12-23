//
//  ZKStatisticsManager.swift
//  ZendyKey
//
//  High-performance typing statistics manager with thread-safe operations
//  Tracks keystrokes, Vietnamese characters, shortcuts, and typing speed
//

import Foundation
import Cocoa
import Combine

// MARK: - Statistics Data Model

struct ZKStatisticsData: Codable {
    // Today's statistics
    var todayKeystrokes: Int = 0
    var todayVietnameseChars: Int = 0
    var todayShortcuts: Int = 0
    var todayAutoRestores: Int = 0
    var todayTypingSeconds: Int = 0
    var lastResetDate: String = ""
    
    // All-time statistics
    var totalKeystrokes: Int = 0
    var totalVietnameseChars: Int = 0
    var totalShortcuts: Int = 0
    var totalAutoRestores: Int = 0
    var totalTypingSeconds: Int = 0
    var startDate: Date = Date()
    
    // Shortcut usage tracking
    var shortcutUsage: [String: Int] = [:]
}

// MARK: - Statistics Manager

final class ZKStatisticsManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ZKStatisticsManager()
    
    // MARK: - Published Properties (for UI binding)
    
    // Today stats
    @Published private(set) var todayKeystrokes: Int = 0
    @Published private(set) var todayVietnameseChars: Int = 0
    @Published private(set) var todayShortcuts: Int = 0
    @Published private(set) var todayAutoRestores: Int = 0
    
    // All-time stats
    @Published private(set) var totalKeystrokes: Int = 0
    @Published private(set) var totalVietnameseChars: Int = 0
    @Published private(set) var totalShortcuts: Int = 0
    @Published private(set) var totalAutoRestores: Int = 0
    
    // Typing speed (real-time) - calculated from active session
    @Published private(set) var wordsPerMinute: Double = 0
    @Published private(set) var charsPerMinute: Double = 0
    
    // Time tracking
    @Published private(set) var totalTypingMinutes: Int = 0
    @Published private(set) var todayTypingMinutes: Int = 0
    @Published private(set) var startDate: Date = Date()
    
    // Top shortcuts
    @Published private(set) var topShortcuts: [(shortcut: String, count: Int)] = []
    
    // MARK: - Private Properties
    
    private var data = ZKStatisticsData()
    
    // Thread safety
    private let queue = DispatchQueue(label: "com.zendy.statistics", qos: .utility)
    
    // Debouncing for persistence
    private var saveWorkItem: DispatchWorkItem?
    private let saveDebounceInterval: TimeInterval = 5.0
    
    // === SMART TYPING SESSION TRACKING ===
    // Session tracking for accurate WPM/CPM calculation
    // A session starts when user types first key
    // Session ends when user stops typing for > sessionIdleThreshold seconds
    
    private var currentSessionStart: Date?              // When current typing session started
    private var lastKeystrokeTime: Date?                // Time of last keystroke
    private var currentSessionKeystrokeCount: Int = 0   // Keystrokes in current session
    private var currentSessionCharCount: Int = 0       // Vietnamese chars in current session
    private let sessionIdleThreshold: TimeInterval = 5.0 // Session ends after 5s idle
    private var accumulatedTypingSeconds: Double = 0    // Fractional seconds accumulator
    
    // Session monitor timer - checks for idle timeout
    private var sessionMonitorTimer: Timer?
    
    // UserDefaults key
    private let storageKey = "ZKStatisticsData"
    
    // MARK: - Initialization
    
    private init() {
        loadFromStorage()
        checkDailyReset()
        startSessionMonitorTimer()
        
        // Listen for app termination to save
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    deinit {
        sessionMonitorTimer?.invalidate()
        saveImmediately()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Tracking Methods (Thread-safe, Non-blocking)
    
    /// Record a keystroke event
    func recordKeystroke() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let now = Date()
            
            // Update counts
            self.data.todayKeystrokes += 1
            self.data.totalKeystrokes += 1
            
            // === SMART SESSION TRACKING ===
            // Check if we need to start a new session
            if let lastTime = self.lastKeystrokeTime {
                let elapsed = now.timeIntervalSince(lastTime)
                
                if elapsed > self.sessionIdleThreshold {
                    // Too long since last keystroke - start new session
                    self.startNewSession(at: now)
                } else {
                    // Within session - accumulate typing time
                    // Use fractional seconds accumulator to prevent Int truncation
                    self.accumulatedTypingSeconds += elapsed
                    
                    // Convert to Int when threshold reached
                    let wholeSeconds = Int(self.accumulatedTypingSeconds)
                    if wholeSeconds >= 1 {
                        self.data.todayTypingSeconds += wholeSeconds
                        self.data.totalTypingSeconds += wholeSeconds
                        self.accumulatedTypingSeconds -= Double(wholeSeconds)
                    }
                }
            } else {
                // First keystroke ever or after reset - start new session
                self.startNewSession(at: now)
            }
            
            // Increment session keystroke count
            self.currentSessionKeystrokeCount += 1
            self.lastKeystrokeTime = now
            
            // Update speed immediately
            self.calculateSessionSpeed()
            
            // Schedule debounced save
            self.scheduleSave()
            
            // Update published values on main thread
            DispatchQueue.main.async {
                self.todayKeystrokes = self.data.todayKeystrokes
                self.totalKeystrokes = self.data.totalKeystrokes
                self.totalTypingMinutes = self.data.totalTypingSeconds / 60
                self.todayTypingMinutes = self.data.todayTypingSeconds / 60
            }
        }
    }

    
    /// Record a Vietnamese character output
    func recordVietnameseChar() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.data.todayVietnameseChars += 1
            self.data.totalVietnameseChars += 1
            
            // Add to current session count for CPM
            self.currentSessionCharCount += 1
            
            // Update speed immediately
            self.calculateSessionSpeed()
            
            self.scheduleSave()
            
            DispatchQueue.main.async {
                self.todayVietnameseChars = self.data.todayVietnameseChars
                self.totalVietnameseChars = self.data.totalVietnameseChars
            }
        }
    }
    
    /// Record a shortcut/macro usage
    func recordShortcut(name: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.data.todayShortcuts += 1
            self.data.totalShortcuts += 1
            
            // Track individual shortcut usage
            let normalizedName = name.lowercased()
            self.data.shortcutUsage[normalizedName, default: 0] += 1
            
            self.scheduleSave()
            
            DispatchQueue.main.async {
                self.todayShortcuts = self.data.todayShortcuts
                self.totalShortcuts = self.data.totalShortcuts
                self.updateTopShortcuts()
            }
        }
    }
    
    /// Record an auto-restore event
    func recordAutoRestore() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.data.todayAutoRestores += 1
            self.data.totalAutoRestores += 1
            
            self.scheduleSave()
            
            DispatchQueue.main.async {
                self.todayAutoRestores = self.data.todayAutoRestores
                self.totalAutoRestores = self.data.totalAutoRestores
            }
        }
    }
    
    // MARK: - Control Methods
    
    /// Reset today's statistics
    func resetTodayStatistics() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.data.todayKeystrokes = 0
            self.data.todayVietnameseChars = 0
            self.data.todayShortcuts = 0
            self.data.todayAutoRestores = 0
            self.data.todayTypingSeconds = 0
            self.data.lastResetDate = self.todayDateString()
            
            // Reset session
            self.endCurrentSession()
            
            self.saveImmediately()
            self.refreshPublishedValues()
        }
    }
    
    /// Reset all statistics
    func resetAllStatistics() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.data = ZKStatisticsData()
            self.data.startDate = Date()
            self.data.lastResetDate = self.todayDateString()
            
            // Reset session
            self.endCurrentSession()
            
            self.saveImmediately()
            self.refreshPublishedValues()
        }
    }
    
    /// Export statistics as formatted string
    func exportStatistics() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "vi_VN")
        
        var output = """
        ═══════════════════════════════════════════
        📊 THỐNG KÊ GÕ PHÍM - ZENDYKEY
        ═══════════════════════════════════════════
        
        📅 Ngày xuất: \(dateFormatter.string(from: Date()))
        📅 Bắt đầu sử dụng: \(dateFormatter.string(from: data.startDate))
        
        ───────────────────────────────────────────
        🗓️ HÔM NAY
        ───────────────────────────────────────────
        ⌨️  Tổng phím gõ:     \(formatNumber(data.todayKeystrokes))
        🇻🇳 Ký tự tiếng Việt: \(formatNumber(data.todayVietnameseChars))
        ⚡ Gõ tắt sử dụng:    \(formatNumber(data.todayShortcuts))
        ↩️  Auto-restore:     \(formatNumber(data.todayAutoRestores))
        ⏱️  Thời gian gõ:     \(data.todayTypingSeconds / 60) phút
        
        ───────────────────────────────────────────
        📈 TẤT CẢ THỜI GIAN
        ───────────────────────────────────────────
        ⌨️  Tổng phím gõ:     \(formatNumber(data.totalKeystrokes))
        🇻🇳 Ký tự tiếng Việt: \(formatNumber(data.totalVietnameseChars))
        ⚡ Gõ tắt sử dụng:    \(formatNumber(data.totalShortcuts))
        ↩️  Auto-restore:     \(formatNumber(data.totalAutoRestores))
        ⏱️  Thời gian gõ:     \(data.totalTypingSeconds / 60) phút
        
        """
        
        // Add top shortcuts if available
        if !data.shortcutUsage.isEmpty {
            output += """
            
            ───────────────────────────────────────────
            ⭐ GÕ TẮT HAY DÙNG
            ───────────────────────────────────────────
            
            """
            
            let sorted = data.shortcutUsage.sorted { $0.value > $1.value }.prefix(10)
            for (index, item) in sorted.enumerated() {
                output += "\(index + 1). \(item.key): \(formatNumber(item.value)) lần\n"
            }
        }
        
        output += """
        
        ═══════════════════════════════════════════
        Xuất bởi ZendyKey - Bộ gõ tiếng Việt
        ═══════════════════════════════════════════
        """
        
        return output
    }
    
    // MARK: - Session Management
    
    /// Start a new typing session
    private func startNewSession(at time: Date) {
        currentSessionStart = time
        currentSessionKeystrokeCount = 0
        currentSessionCharCount = 0
    }
    
    /// End current session and reset speed
    private func endCurrentSession() {
        currentSessionStart = nil
        currentSessionKeystrokeCount = 0
        currentSessionCharCount = 0
        lastKeystrokeTime = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.wordsPerMinute = 0
            self?.charsPerMinute = 0
        }
    }
    
    /// Calculate WPM/CPM based on current session duration
    private func calculateSessionSpeed() {
        guard let sessionStart = currentSessionStart else {
            // No active session
            DispatchQueue.main.async { [weak self] in
                self?.wordsPerMinute = 0
                self?.charsPerMinute = 0
            }
            return
        }
        
        let now = Date()
        let sessionDuration = now.timeIntervalSince(sessionStart)
        
        // Minimum 1 second to avoid division by zero or unrealistic speeds
        let durationMinutes = max(sessionDuration / 60.0, 1.0 / 60.0)
        
        // WPM: keystrokes / 5 = words (standard typing test convention)
        let wpm = Double(currentSessionKeystrokeCount) / 5.0 / durationMinutes
        
        // CPM: Vietnamese characters output per minute
        let cpm = Double(currentSessionCharCount) / durationMinutes
        
        DispatchQueue.main.async { [weak self] in
            self?.wordsPerMinute = min(wpm, 300) // Cap at realistic max
            self?.charsPerMinute = min(cpm, 600) // Cap at realistic max
        }
    }
    
    // MARK: - Session Monitor Timer
    
    /// Timer that monitors for idle state and resets speed when session ends
    private func startSessionMonitorTimer() {
        sessionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkSessionTimeout()
        }
    }
    
    /// Check if user has been idle too long and end session if so
    private func checkSessionTimeout() {
        queue.async { [weak self] in
            guard let self = self,
                  let lastTime = self.lastKeystrokeTime else {
                return
            }
            
            let elapsed = Date().timeIntervalSince(lastTime)
            
            if elapsed > self.sessionIdleThreshold {
                // User stopped typing - end session and reset speed
                self.endCurrentSession()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkDailyReset() {
        let today = todayDateString()
        if data.lastResetDate != today {
            // New day - reset today's stats
            data.todayKeystrokes = 0
            data.todayVietnameseChars = 0
            data.todayShortcuts = 0
            data.todayAutoRestores = 0
            data.todayTypingSeconds = 0
            data.lastResetDate = today
            saveImmediately()
        }
    }
    
    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func updateTopShortcuts() {
        let sorted = data.shortcutUsage.sorted { $0.value > $1.value }.prefix(10)
        topShortcuts = sorted.map { ($0.key, $0.value) }
    }
    
    private func refreshPublishedValues() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.todayKeystrokes = self.data.todayKeystrokes
            self.todayVietnameseChars = self.data.todayVietnameseChars
            self.todayShortcuts = self.data.todayShortcuts
            self.todayAutoRestores = self.data.todayAutoRestores
            
            self.totalKeystrokes = self.data.totalKeystrokes
            self.totalVietnameseChars = self.data.totalVietnameseChars
            self.totalShortcuts = self.data.totalShortcuts
            self.totalAutoRestores = self.data.totalAutoRestores
            
            self.totalTypingMinutes = self.data.totalTypingSeconds / 60
            self.todayTypingMinutes = self.data.todayTypingSeconds / 60
            self.startDate = self.data.startDate
            
            self.updateTopShortcuts()
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // MARK: - Persistence
    
    private func scheduleSave() {
        saveWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveImmediately()
        }
        
        saveWorkItem = workItem
        queue.asyncAfter(deadline: .now() + saveDebounceInterval, execute: workItem)
    }
    
    private func saveImmediately() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self.data)
                UserDefaults.standard.set(data, forKey: self.storageKey)
            } catch {
                print("ZKStatisticsManager: Failed to save data: \(error)")
            }
        }
    }
    
    private func loadFromStorage() {
        guard let storedData = UserDefaults.standard.data(forKey: storageKey) else {
            // First time - set start date
            data.startDate = Date()
            data.lastResetDate = todayDateString()
            return
        }
        
        do {
            let decoder = JSONDecoder()
            data = try decoder.decode(ZKStatisticsData.self, from: storedData)
            refreshPublishedValues()
        } catch {
            print("ZKStatisticsManager: Failed to load data: \(error)")
            // Reset to defaults on error
            data = ZKStatisticsData()
            data.startDate = Date()
            data.lastResetDate = todayDateString()
        }
    }
    
    @objc private func appWillTerminate() {
        saveImmediately()
    }
}
