//
//  ZKEnglishDictionary.swift
//  ZendyKey
//
//  English dictionary for auto-restore detection.
//  Uses merged dictionary: 10k common words + words with double telex chars.
//  Only restores to English when raw_input is a known English word.
//
//  Ported from gonhanh.org/core/src/data/english_dict.rs
//

import Foundation

/// English Dictionary for auto-restore validation
/// Uses O(1) Set lookup for fast dictionary checking
class ZKEnglishDictionary {
    
    // MARK: - Singleton
    
    static let shared = ZKEnglishDictionary()
    
    // MARK: - Dictionary Data
    
    /// Lazy-loaded Set of English words for O(1) lookup
    private lazy var dictionary: Set<String> = {
        loadDictionary()
    }()
    
    /// Dictionary word count
    var wordCount: Int {
        return dictionary.count
    }
    
    private init() {}
    
    // MARK: - Public API
    
    /// Check if a word is in the English dictionary (case-insensitive)
    /// - Parameter word: The word to check
    /// - Returns: True if the word is a known English word
    func isEnglishWord(_ word: String) -> Bool {
        let lower = word.lowercased()
        return dictionary.contains(lower)
    }
    
    /// Check if a word contains typical Telex double patterns
    /// Used to detect words like "beer", "see", "too", "add" etc.
    /// - Parameter word: The raw input word
    /// - Returns: True if word contains double Telex patterns
    func hasDoubleTelexPattern(_ word: String) -> Bool {
        let lower = word.lowercased()
        
        // Telex double patterns:
        // - aa, ee, oo (double vowels - circumflex triggers)
        // - ss, ff, rr, xx, jj (double tone modifiers)
        // - dd (stroke trigger)
        let doublePatterns = ["aa", "ee", "oo", "ss", "ff", "rr", "xx", "jj", "dd"]
        
        for pattern in doublePatterns {
            if lower.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    /// Check if word is likely an English word with Telex patterns
    /// Combines dictionary check + pattern detection for better accuracy
    /// - Parameter word: The raw input word
    /// - Returns: True if word is English with Telex patterns
    func isEnglishWordWithTelexPattern(_ word: String) -> Bool {
        return hasDoubleTelexPattern(word) && isEnglishWord(word)
    }
    
    // MARK: - Dictionary Loading
    
    /// Load dictionary from bundled resource file
    private func loadDictionary() -> Set<String> {
        var words = Set<String>()
        
        // Try to load 100k dictionary first (comprehensive)
        // Fallback to merged dictionary if 100k not available
        let resourceNames = ["ZKEnglish100k", "ZKEnglishDictMerged"]
        
        for resourceName in resourceNames {
            if let url = Bundle.main.url(forResource: resourceName, withExtension: "txt"),
               let contents = try? String(contentsOf: url, encoding: .utf8) {
                let lines = contents.components(separatedBy: .newlines)
                for line in lines {
                    let word = line.trimmingCharacters(in: .whitespaces)
                    if !word.isEmpty {
                        words.insert(word.lowercased())
                    }
                }
                ZKDebugLogger.shared.info("Loaded \(words.count) English words from \(resourceName)", source: "EnglishDict")
                return words
            }
        }
        
        // Fallback: embed common words (no resource file available)
        let commonWords = [
            "a", "about", "above", "across", "add", "added", "address",
            "after", "again", "against", "all", "allow", "also", "always",
            "beer", "been", "before", "begin", "best", "better", "between",
            "coffee", "command", "comment", "committee", "common", "community",
            "effect", "effective", "effort", "errors", "express",
            "fee", "feed", "feel", "feelings", "feet", "free",
            "issue", "issues",
            "mass", "matter", "meet", "meeting",
            "need", "needs", "off", "offer", "office",
            "pass", "password", "poor", "process", "processing", "programming",
            "see", "seed", "seeing", "seen", "seem", "seems",
            "success", "successful", "teen", "teenager",
            "too", "took", "tool", "tree",
            "week", "weeks", "wood", "would"
        ]
        words = Set(commonWords)
        ZKDebugLogger.shared.warning("Using fallback English dictionary (\(words.count) words)", source: "EnglishDict")
        return words
    }
}
