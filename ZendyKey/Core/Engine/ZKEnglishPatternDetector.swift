//
//  ZKEnglishPatternDetector.swift
//  ZendyKey
//
//  English pattern detection for auto-restore feature.
//

import Foundation

/// Detects English word patterns to improve auto-restore accuracy.
/// Uses 5-tier pattern detection.
struct ZKEnglishPatternDetector {
    
    // MARK: - Tier 3: English-only Coda Clusters
    
    /// English-only coda clusters that don't exist in Vietnamese
    /// From spec: ct, ft, ld, lf, lk, lm, lp, lt, nd, nk, nt, pt, rb, rd, rk, rm, rn, rp, rt, sk, sp, st, sh, xt
    private static let englishCodaClusters: Set<String> = [
        "ct", "ft", "ld", "lf", "lk", "lm", "lp", "lt",
        "nd", "nk", "nt", "pt", "rb", "rd", "rk", "rm",
        "rn", "rp", "rt", "sk", "sp", "st", "sh", "xt"
    ]
    
    /// Tier 3: Check for English-only coda clusters at end of word
    static func hasCodaCluster(_ word: String) -> Bool {
        let lower = word.lowercased()
        guard lower.count >= 2 else { return false }
        
        let last2 = String(lower.suffix(2))
        return englishCodaClusters.contains(last2)
    }
    
    // MARK: - Tier 4: English-only Vowel Patterns
    
    /// English-only vowel patterns
    /// Note: "ee", "oo" excluded (Telex modifiers for ê, ô)
    /// Note: "eu", "io" excluded (can appear in VN transforms)
    private static let englishVowelPatterns: Set<String> = [
        "ea", "ou", "ei", "yo", "ae", "yi"
    ]
    
    /// Tier 4: Check for English-only vowel patterns
    static func hasVowelPattern(_ word: String) -> Bool {
        let lower = word.lowercased()
        return englishVowelPatterns.contains { lower.contains($0) }
    }
    
    // MARK: - Tier 5: English Suffixes
    
    /// Common English suffixes
    private static let englishSuffixes: [String] = [
        "tion", "sion", "ness", "ment", "able", "ible",
        "ing", "ful", "ous", "ive", "less", "ness"
    ]
    
    /// Tier 5: Check for English suffixes
    static func hasSuffix(_ word: String) -> Bool {
        let lower = word.lowercased()
        return englishSuffixes.contains { lower.hasSuffix($0) }
    }
    
    // MARK: - Tier 6: VCV Patterns (Vowel-Consonant-final e)
    
    /// English VCV patterns (vowel + consonant + silent 'e')
    private static let vcvPatterns: Set<String> = [
        "ore", "are", "ile", "ure", "ife", "ive", "ase",
        "ose", "use", "ade", "ide", "ode", "ude", "ate",
        "ite", "ote", "ute", "ane", "ine", "one", "une"
    ]
    
    /// Tier 6: Check for VCV patterns
    static func hasVCVPattern(_ word: String) -> Bool {
        let lower = word.lowercased()
        guard lower.count >= 3 else { return false }
        
        let last3 = String(lower.suffix(3))
        return vcvPatterns.contains(last3)
    }
    
    // MARK: - Tier 7: W as Vowel
    
    /// Patterns where 'w' acts as a vowel (English-only)
    private static let wAsVowelPatterns: Set<String> = [
        "ew", "ow", "aw", "iew"
    ]
    
    /// Tier 7: Check for 'w' used as vowel (English pattern)
    static func hasWAsVowel(_ word: String) -> Bool {
        let lower = word.lowercased()
        
        // 'w' at start is consonant (win, water)
        // 'w' in middle/end as part of diphthong is vowel (new, show, law)
        return wAsVowelPatterns.contains { pattern in
            if pattern == "iew" {
                return lower.contains(pattern)
            }
            // For 2-char patterns, check they're at end
            return lower.hasSuffix(pattern)
        }
    }
    
    // MARK: - Combined Detection
    
    /// Check if word matches any English pattern (Tier 3-7)
    /// - Parameter word: The raw input word to check
    /// - Returns: true if word matches English patterns
    static func isEnglish(_ word: String) -> Bool {
        return hasCodaCluster(word)
            || hasVowelPattern(word)
            || hasSuffix(word)
            || hasVCVPattern(word)
            || hasWAsVowel(word)
    }
}
