//
//  ZKVietnameseDictionary.swift
//  ZendyKey
//
//  Vietnamese word dictionary for spell checking and word detection.
//

import Foundation

/// Vietnamese Dictionary for word validation and spell checking
class ZKVietnameseDictionary {
    
    // MARK: - Singleton
    
    static let shared = ZKVietnameseDictionary()
    
    // MARK: - Dictionary Data
    
    /// Lazy-loaded Set of Vietnamese words for O(1) lookup
    private lazy var dictionary: Set<String> = {
        loadDictionary()
    }()
    
    /// Word count
    var wordCount: Int {
        return dictionary.count
    }
    
    private init() {}
    
    // MARK: - Public API
    
    /// Check if a word/phrase is a valid Vietnamese word
    /// - Parameter word: The word to check (case-insensitive, with diacritics)
    /// - Returns: True if the word is in Vietnamese dictionary
    func isVietnameseWord(_ word: String) -> Bool {
        let lower = word.lowercased()
        return dictionary.contains(lower)
    }
    
    /// Check if a string contains only valid Vietnamese syllables
    /// Splits by spaces and checks each syllable
    /// - Parameter text: Text to validate
    /// - Returns: True if all syllables are valid Vietnamese
    func isValidVietnamesePhrase(_ text: String) -> Bool {
        let words = text.lowercased().components(separatedBy: " ")
        for word in words where !word.isEmpty {
            if !dictionary.contains(word) {
                return false
            }
        }
        return true
    }
    
    /// Get suggestions for a misspelled word (basic fuzzy match)
    /// - Parameter word: The misspelled word
    /// - Parameter limit: Maximum suggestions to return
    /// - Returns: Array of suggested words
    func getSuggestions(for word: String, limit: Int = 5) -> [String] {
        let lower = word.lowercased()
        var suggestions: [String] = []
        
        // Simple prefix match
        for dictWord in dictionary {
            if dictWord.hasPrefix(String(lower.prefix(2))) && 
               abs(dictWord.count - lower.count) <= 2 {
                suggestions.append(dictWord)
                if suggestions.count >= limit {
                    break
                }
            }
        }
        
        return suggestions
    }
    
    // MARK: - Loading
    
    private func loadDictionary() -> Set<String> {
        var words = Set<String>()
        
        // Load from bundle resource
        if let url = Bundle.main.url(forResource: "ZKVietnamese22k", withExtension: "txt"),
           let contents = try? String(contentsOf: url, encoding: .utf8) {
            let lines = contents.components(separatedBy: .newlines)
            for line in lines {
                let word = line.trimmingCharacters(in: .whitespaces)
                if !word.isEmpty {
                    words.insert(word.lowercased())
                }
            }
        } else {
            // Fallback: common Vietnamese words
            let common = [
                "xin", "chào", "cảm", "ơn", "tạm", "biệt", "vâng", "không",
                "có", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín", "mười",
                "ngày", "tháng", "năm", "giờ", "phút", "giây",
                "tôi", "bạn", "anh", "chị", "em", "ông", "bà", "cô", "chú",
                "đi", "đến", "về", "lên", "xuống", "vào", "ra",
                "ăn", "uống", "ngủ", "học", "làm", "việc", "chơi"
            ]
            words = Set(common)
            ZKDebugLogger.shared.warning("Could not load zk_vietnamese_22k.txt, using fallback", source: "VNDict")
        }
        
        ZKDebugLogger.shared.info("Loaded \(words.count) Vietnamese words", source: "VNDict")
        return words
    }
}
