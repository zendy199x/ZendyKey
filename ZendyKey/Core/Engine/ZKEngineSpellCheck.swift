//
//  ZKEngineSpellCheck.swift
//  ZendyKey
//
//  Extension for ZKEngine to support spell checking
//

import Foundation
import AppKit

/// Extension for ZKEngine to support spell checking
extension ZKEngine {

    /// Validate if the current word buffer is a valid Vietnamese word
    func isCurrentWordValid() -> Bool {
        guard ZKSharedSettings.shared.spellCheckEnabled else {
            logCallback?("📖 Dictionary check: DISABLED (spellCheckEnabled=false)")
            return true // Spell checking disabled
        }

        let currentWord = self.getCurrentWord()
        guard !currentWord.isEmpty else {
            logCallback?("📖 Dictionary check: SKIPPED (empty word)")
            return true // Empty word is considered valid
        }

        // When vAllowConsonantZFWJ is enabled, words containing Z, F, W, J consonants
        // should be considered valid without dictionary check
        // This allows foreign-influenced Vietnamese words like "zị", "wốn", etc.
        if vAllowConsonantZFWJ == 1 {
            let lowercaseWord = currentWord.lowercased()
            let specialConsonants: [Character] = ["z", "f", "w", "j"]
            
            // Check if word starts with or contains these consonants
            if let firstChar = lowercaseWord.first, specialConsonants.contains(firstChar) {
                logCallback?("📖 Dictionary check: SKIPPED (vAllowConsonantZFWJ=1, starts with '\(firstChar)')")
                return true
            }
            
            // Also check if word contains these consonants anywhere (for compound words)
            for consonant in specialConsonants {
                if lowercaseWord.contains(consonant) {
                    logCallback?("📖 Dictionary check: SKIPPED (vAllowConsonantZFWJ=1, contains '\(consonant)')")
                    return true
                }
            }
        }
        
        // First, check user dictionary (custom words defined by user)
        if ZKSharedSettings.shared.isWordInUserDictionary(currentWord) {
            logCallback?("📖 Dictionary check: FOUND in User Dictionary, word='\(currentWord)'")
            return true // Word is in user dictionary, considered valid
        }

        // Check against hunspell dictionary
        let style: ZKDictionaryManager.DictionaryStyle = ZKSharedSettings.shared.modernStyle ? .newStyle : .oldStyle
        let styleName = style == .oldStyle ? "Dấu cũ" : "Dấu mới"
        
        let isDictionaryLoaded = ZKDictionaryManager.shared.isDictionaryLoaded(style: style)
        if !isDictionaryLoaded {
            logCallback?("📖 Dictionary check: NOT LOADED (style=\(styleName))")
            return true // Dictionary not loaded, assume valid
        }
        
        let isValid = ZKDictionaryManager.shared.isValidWord(currentWord, style: style)
        logCallback?("📖 Dictionary check: word='\(currentWord)', style=\(styleName), valid=\(isValid)")

        if isValid {
            return true
        }

        // If not found in dictionary, use Natural Language framework as fallback
        let nlValid = isValidWordUsingNaturalLanguage(currentWord)
        logCallback?("📖 NaturalLanguage check: word='\(currentWord)', valid=\(nlValid)")

        return nlValid
    }

    /// Validate if a given word string is a valid Vietnamese word
    /// This is used for checking words from Accessibility API
    func checkWordSpelling(word: String) -> Bool {
        guard ZKSharedSettings.shared.spellCheckEnabled else {
            logCallback?("📖 checkWordSpelling: DISABLED (spellCheckEnabled=false)")
            return true // Spell checking disabled
        }

        guard !word.isEmpty else {
            logCallback?("📖 checkWordSpelling: SKIPPED (empty word)")
            return true // Empty word is considered valid
        }

        // When vAllowConsonantZFWJ is enabled, words containing Z, F, W, J consonants
        // should be considered valid without dictionary check
        if vAllowConsonantZFWJ == 1 {
            let lowercaseWord = word.lowercased()
            let specialConsonants: [Character] = ["z", "f", "w", "j"]

            if let firstChar = lowercaseWord.first, specialConsonants.contains(firstChar) {
                logCallback?("📖 checkWordSpelling: SKIPPED (vAllowConsonantZFWJ=1, starts with '\(firstChar)')")
                return true
            }

            for consonant in specialConsonants {
                if lowercaseWord.contains(consonant) {
                    logCallback?("📖 checkWordSpelling: SKIPPED (vAllowConsonantZFWJ=1, contains '\(consonant)')")
                    return true
                }
            }
        }

        // Check user dictionary
        if ZKSharedSettings.shared.isWordInUserDictionary(word) {
            logCallback?("📖 checkWordSpelling: FOUND in User Dictionary, word='\(word)'")
            return true
        }

        // Check against hunspell dictionary
        let style: ZKDictionaryManager.DictionaryStyle = ZKSharedSettings.shared.modernStyle ? .newStyle : .oldStyle
        let styleName = style == .oldStyle ? "Dấu cũ" : "Dấu mới"

        let isDictionaryLoaded = ZKDictionaryManager.shared.isDictionaryLoaded(style: style)
        if !isDictionaryLoaded {
            logCallback?("📖 checkWordSpelling: NOT LOADED (style=\(styleName))")
            return true
        }

        let isValid = ZKDictionaryManager.shared.isValidWord(word, style: style)
        logCallback?("📖 checkWordSpelling: word='\(word)', style=\(styleName), valid=\(isValid)")

        if isValid {
            return true
        }

        // Fallback to Natural Language framework
        let nlValid = isValidWordUsingNaturalLanguage(word)
        logCallback?("📖 checkWordSpelling NL: word='\(word)', valid=\(nlValid)")

        return nlValid
    }

    /// Check if word is valid using macOS Natural Language framework
    /// This serves as a fallback when word is not found in the custom dictionary
    private func isValidWordUsingNaturalLanguage(_ word: String) -> Bool {
        // Use NLSpellChecker to check spelling
        let checker = NSSpellChecker.shared

        // Check spelling for Vietnamese language
        let range = checker.checkSpelling(of: word, startingAt: 0, language: "vi", wrap: false, inSpellDocumentWithTag: 0, wordCount: nil)

        // If range.location == NSNotFound, the word is correctly spelled
        let isCorrect = range.location == NSNotFound

        return isCorrect
    }

    /// Get spell check suggestion status for the word
    func getSpellCheckStatus() -> ZKSpellCheckStatus {
        guard ZKSharedSettings.shared.spellCheckEnabled else {
            return .disabled
        }

        let style: ZKDictionaryManager.DictionaryStyle = ZKSharedSettings.shared.modernStyle ? .newStyle : .oldStyle
        guard ZKDictionaryManager.shared.isDictionaryLoaded(style: style) else {
            return .dictionaryNotLoaded
        }

        let currentWord = self.getCurrentWord()
        guard !currentWord.isEmpty else {
            return .valid
        }

        if isCurrentWordValid() {
            return .valid
        } else {
            return .invalid(word: currentWord)
        }
    }

    /// Find similar words for spell correction suggestions
    func getSuggestions(for word: String, maxSuggestions: Int = 5) -> [String] {
        guard ZKSharedSettings.shared.spellCheckEnabled,
              ZKDictionaryManager.shared.isDictionaryLoaded() else {
            return []
        }

        // For now, return empty array
        // TODO: Implement edit distance based suggestions
        return []
    }
}

// MARK: - Supporting Types

enum ZKSpellCheckStatus: Equatable {
    case disabled
    case dictionaryNotLoaded
    case valid
    case invalid(word: String)

    var isValid: Bool {
        switch self {
        case .valid, .disabled, .dictionaryNotLoaded:
            return true
        case .invalid:
            return false
        }
    }

    var needsDownload: Bool {
        if case .dictionaryNotLoaded = self {
            return true
        }
        return false
    }
}
