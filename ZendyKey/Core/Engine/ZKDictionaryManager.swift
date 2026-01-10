//
//  ZKDictionaryManager.swift
//  ZendyKey
//
//  Manager for Vietnamese dictionary files for spell checking
//  Dictionaries are bundled with the app for offline usage
//

import Foundation

/// Manager for Vietnamese dictionary files for spell checking
/// Dictionaries are bundled directly in the app's Resources folder
class ZKDictionaryManager {
    static let shared = ZKDictionaryManager()

    // Bundled dictionary file names (without extension)
    // - newStyle = "Dấu mới" = New punctuation style (common in Vietnam) - hoà, khoè, thuỷ
    // - oldStyle = "Dấu cũ" = Old punctuation style (common abroad) - hòa, khòe, thùy
    private let bundledDictionaries: [DictionaryStyle: String] = [
        .newStyle: "ZKNewPunctuation",
        .oldStyle: "ZKOldPunctuation"
    ]

    // In-memory dictionary cache
    private var wordSets: [DictionaryStyle: Set<String>] = [:]
    private var isLoading = false

    private init() {}

    // MARK: - Public API

    /// Check if a word exists in the dictionary (either user dictionary or hunspell dictionary)
    func isValidWord(_ word: String, style: DictionaryStyle = .newStyle) -> Bool {
        // Normalize the word (lowercase and remove tones for checking)
        let normalized = word.lowercased().trimmingCharacters(in: .whitespaces)
        
        // First, check user dictionary (custom words defined by user)
        if ZKSharedSettings.shared.isWordInUserDictionary(normalized) {
            return true // Word is in user dictionary, skip spell check
        }
        
        // Then check hunspell dictionary
        guard let wordSet = wordSets[style] else {
            return false // Dictionary not loaded
        }

        return wordSet.contains(normalized)
    }

    /// Check if dictionaries are available (bundled with app)
    func isDictionaryAvailable(style: DictionaryStyle = .newStyle) -> Bool {
        guard let fileName = bundledDictionaries[style] else {
            return false
        }
        return Bundle.main.url(forResource: fileName, withExtension: "txt") != nil
    }

    /// Check if dictionary is loaded in memory
    func isDictionaryLoaded(style: DictionaryStyle = .newStyle) -> Bool {
        return wordSets[style] != nil
    }

    /// Load dictionary from bundled resources into memory
    func loadDictionary(style: DictionaryStyle = .newStyle) throws {
        guard let fileName = bundledDictionaries[style] else {
            sharedLogError("[ZKDict] Unknown dictionary style: \(style)")
            throw DictionaryError.fileNotFound
        }
        
        guard let bundleURL = Bundle.main.url(forResource: fileName, withExtension: "txt") else {
            sharedLogError("[ZKDict] Dictionary not found in bundle: \(fileName).txt")
            throw DictionaryError.fileNotFound
        }
        
        sharedLogInfo("[ZKDict] Loading from bundle: \(bundleURL.lastPathComponent)")

        let content = try String(contentsOf: bundleURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        // First line is word count, skip it
        var words = Set<String>()
        for (index, line) in lines.enumerated() {
            guard index > 0, !line.isEmpty else { continue }

            // Some entries may have flags (e.g., "word/flags"), we only need the word part
            let word = line.components(separatedBy: "/").first ?? line
            words.insert(word.lowercased().trimmingCharacters(in: .whitespaces))
        }

        wordSets[style] = words
        sharedLogInfo("[ZKDict] Loaded \(words.count) words from \(style.displayName) dictionary")
    }

    /// Load dictionary if available and not already loaded
    func loadIfAvailable(style: DictionaryStyle = .newStyle) {
        guard isDictionaryAvailable(style: style), !isDictionaryLoaded(style: style) else {
            return
        }

        try? loadDictionary(style: style)
    }
    
    /// Load both dictionaries
    func loadAllDictionaries() {
        for style in [DictionaryStyle.newStyle, DictionaryStyle.oldStyle] {
            loadIfAvailable(style: style)
        }
    }

    /// Get dictionary statistics
    func getDictionaryStats() -> [String: Int] {
        var stats: [String: Int] = [:]
        for (style, wordSet) in wordSets {
            stats[style.displayName] = wordSet.count
        }
        return stats
    }

    /// Clear loaded dictionaries from memory
    func clearCache() {
        wordSets.removeAll()
    }
}

// MARK: - Supporting Types

extension ZKDictionaryManager {
    enum DictionaryStyle: String, CaseIterable {
        case newStyle = "ZKNewPunctuation"  // "Dấu mới" - Reformed style (common in Vietnam) - hoà, khoè, thuỷ
        case oldStyle = "ZKOldPunctuation"  // "Dấu cũ" - Traditional style (common abroad) - hòa, khòe, thùy
        
        var displayName: String {
            switch self {
            case .newStyle: return "Dấu mới"
            case .oldStyle: return "Dấu cũ"
            }
        }
    }

    enum DictionaryError: LocalizedError {
        case fileNotFound
        case parseError

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Dictionary file not found in app bundle"
            case .parseError:
                return "Failed to parse dictionary file"
            }
        }
    }
}
