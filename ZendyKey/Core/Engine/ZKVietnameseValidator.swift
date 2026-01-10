//
//  ZKVietnameseValidator.swift
//  ZendyKey
//
//  9-Layer Vietnamese syllable validation with O(1) bitmask operations.
//

import Foundation

/// Validation result for Vietnamese syllable
enum VnState: Equatable {
    case complete       // Valid complete syllable
    case incomplete     // Could become valid (consonant-only)
    case impossible     // Cannot be valid Vietnamese
}

/// 9-Layer Vietnamese syllable validator using O(1) bitmask operations
struct ZKVietnameseValidator {
    
    // MARK: - Parsed Syllable Structure
    
    struct Syllable {
        var onset: [Character] = []   // Initial consonant(s)
        var vowels: [Character] = []  // Vowel nucleus
        var coda: [Character] = []    // Final consonant(s)
        var tone: UInt8 = 0           // Tone mark (0=none)
        
        var onsetStr: String { String(onset).lowercased() }
        var codaStr: String { String(coda).lowercased() }
        var vowelsBase: [Character] { vowels.map { ZKTonePlacement.getBaseVowel($0) } }
    }
    
    // MARK: - Character Type Constants
    
    static let ONSET: UInt8   = 0b0001
    static let VOWEL: UInt8   = 0b0010
    static let CODA: UInt8    = 0b0100
    static let INVALID: UInt8 = 0b1000
    
    // MARK: - Character Index Mapping
    
    /// Map character to index: a=0, b=1, ..., z=25, đ=26, ă=27, â=28, ê=29, ô=30, ơ=31, ư=32
    static func charIdx(_ c: Character) -> Int {
        let lower = c.lowercased().first ?? c
        switch lower {
        case "a"..."z":
            return Int(lower.asciiValue! - Character("a").asciiValue!)
        case "đ": return 26
        case "ă": return 27
        case "â": return 28
        case "ê": return 29
        case "ô": return 30
        case "ơ": return 31
        case "ư": return 32
        default: return 33  // Invalid
        }
    }
    
    // MARK: - Character Type Table (33 entries)
    
    /// Character type lookup: a=0, b=1, ..., z=25, đ=26, ă=27, â=28, ê=29, ô=30, ơ=31, ư=32
    static let charType: [UInt8] = [
        // a      b      c           d      e      f        g      h
        VOWEL, ONSET, ONSET | CODA, ONSET, VOWEL, INVALID, ONSET, ONSET,
        // i           j        k      l      m           n           o           p
        VOWEL | CODA, INVALID, ONSET, ONSET, ONSET | CODA, ONSET | CODA, VOWEL | CODA, ONSET | CODA,
        // q      r      s      t           u           v      w        x
        ONSET, ONSET, ONSET, ONSET | CODA, VOWEL | CODA, ONSET, INVALID, ONSET,
        // y           z        đ      ă      â      ê      ô      ơ      ư
        VOWEL | CODA, INVALID, ONSET, VOWEL, VOWEL, VOWEL, VOWEL, VOWEL, VOWEL
    ]
    
    // MARK: - Bitmask Constants
    
    /// Valid single onsets: b,c,d,đ,g,h,k,l,m,n,p,q,r,s,t,v,x
    /// Precomputed: bits 1,2,3,6,7,10,11,12,13,15,16,17,18,19,21,23,26
    static let mOnset: UInt32 = 0x04AF_BCCE  // Precomputed value
    
    /// Valid single codas: c,m,n,p,t + semi-vowels i,o,u,y
    /// Precomputed: bits 2,8,12,13,14,15,19,20,24
    static let mCoda: UInt32 = 0x0118_F104   // Precomputed value
    
    // MARK: - Valid Clusters
    
    /// Valid onset clusters (2-char)
    static let vnOnsetClusters: Set<String> = [
        "ch", "gh", "gi", "kh", "ng", "nh", "ph", "qu", "th", "tr"
    ]
    
    /// Valid coda clusters
    static let vnCodaClusters: Set<String> = ["ch", "ng", "nh"]
    
    // MARK: - Valid Diphthongs and Triphthongs
    
    static let validDiphthongs: Set<String> = [
        "ai", "ao", "au", "ay", "âu", "ây", "eo", "êu",
        "ia", "iê", "iu", "oa", "oă", "oe", "oi", "ôi", "ơi",
        "ua", "uâ", "uê", "ui", "uô", "uơ", "uy",
        "ưa", "ưi", "ươ", "ưu", "yê"
    ]
    
    static let validTriphthongs: Set<String> = [
        "iêu", "yêu", "oai", "oay", "oao", "oeo",
        "uây", "uôi", "uya", "uyê", "uyu", "uêu", "ươi", "ươu"
    ]
    
    // MARK: - Main Validation API
    
    /// Validate buffer as Vietnamese syllable
    static func validate(_ buffer: String) -> VnState {
        guard !buffer.isEmpty else { return .incomplete }
        
        let syllable = parseSyllable(buffer)
        
        // L1: Character type check
        guard checkCharTypes(buffer) else { return .impossible }
        
        // L2-L3: Onset validation
        guard checkOnset(syllable) else { return .impossible }
        
        // L4: Vowel pattern validation
        if syllable.vowels.isEmpty {
            // Consonant-only is incomplete
            return .incomplete
        }
        guard checkVowelPattern(syllable) else { return .impossible }
        
        // L5-L6: Coda validation
        guard checkCoda(syllable) else { return .impossible }
        
        // L7: Tone-stop restriction
        guard checkToneStop(syllable) else { return .impossible }
        
        // L8: Spelling rules
        guard checkSpelling(syllable) else { return .impossible }
        
        // L9: Modifier requirements
        guard checkModifierReq(syllable) else { return .impossible }
        
        return .complete
    }
    
    // MARK: - Syllable Parser
    
    /// Parse buffer into syllable structure (onset, vowels, coda)
    static func parseSyllable(_ buffer: String) -> Syllable {
        var syllable = Syllable()
        let chars = Array(buffer)
        var idx = 0
        
        // Parse onset (consonant cluster at start)
        while idx < chars.count {
            let c = chars[idx]
            let isVowel = ZKTonePlacement.isVowel(c)
            
            // Handle "gi" cluster
            if syllable.onset.count == 1 &&
               syllable.onset[0].lowercased() == "g" &&
               c.lowercased() == "i" {
                if idx + 1 < chars.count && ZKTonePlacement.isVowel(chars[idx + 1]) {
                    syllable.onset.append(c)
                    idx += 1
                    continue
                }
            }
            
            // Handle "qu" cluster
            if syllable.onset.count == 1 &&
               syllable.onset[0].lowercased() == "q" &&
               c.lowercased() == "u" {
                syllable.onset.append(c)
                idx += 1
                continue
            }
            
            if isVowel {
                break
            }
            syllable.onset.append(c)
            idx += 1
        }
        
        // Parse vowels (nucleus)
        while idx < chars.count {
            let c = chars[idx]
            let baseVowel = ZKTonePlacement.getBaseVowel(c)
            if ZKTonePlacement.isVowel(c) {
                syllable.vowels.append(baseVowel)
                // Track tone
                if hasTone(c) {
                    syllable.tone = getTone(c)
                }
                idx += 1
            } else {
                break
            }
        }
        
        // Parse coda (remaining consonants)
        while idx < chars.count {
            syllable.coda.append(chars[idx])
            idx += 1
        }
        
        return syllable
    }
    
    // MARK: - Layer Checks
    
    /// L1: Check all characters are valid Vietnamese
    static func checkCharTypes(_ buffer: String) -> Bool {
        for c in buffer {
            let idx = charIdx(ZKTonePlacement.getBaseVowel(c))
            if idx >= charType.count || (charType[idx] & INVALID) != 0 {
                // Check if it's a valid toned vowel
                if !ZKTonePlacement.isVowel(c) && idx >= charType.count {
                    return false
                }
            }
        }
        return true
    }
    
    /// L2-L3: Check onset validity
    static func checkOnset(_ syllable: Syllable) -> Bool {
        let onset = syllable.onsetStr
        
        if onset.isEmpty { return true }
        
        // Single consonant
        if onset.count == 1 {
            let idx = charIdx(onset.first!)
            return idx < 26 && (mOnset & (1 << idx)) != 0
        }
        
        // 2-char cluster
        if onset.count == 2 {
            return vnOnsetClusters.contains(onset)
        }
        
        // 3-char cluster (only "ngh")
        if onset.count == 3 {
            return onset == "ngh"
        }
        
        return false
    }
    
    /// L4: Check vowel pattern validity
    static func checkVowelPattern(_ syllable: Syllable) -> Bool {
        let vowels = String(syllable.vowelsBase)
        
        switch vowels.count {
        case 0: return true
        case 1: return true  // Single vowel always valid
        case 2: return validDiphthongs.contains(vowels)
        case 3: return validTriphthongs.contains(vowels)
        default: return false
        }
    }
    
    /// L5-L6: Check coda validity
    static func checkCoda(_ syllable: Syllable) -> Bool {
        let coda = syllable.codaStr
        
        if coda.isEmpty { return true }
        
        // Single consonant
        if coda.count == 1 {
            let idx = charIdx(coda.first!)
            return idx < 26 && (mCoda & (1 << idx)) != 0
        }
        
        // 2-char cluster
        if coda.count == 2 {
            return vnCodaClusters.contains(coda)
        }
        
        return false
    }
    
    /// L7: Tone-stop restriction (stop codas only allow sắc and nặng)
    static func checkToneStop(_ syllable: Syllable) -> Bool {
        let coda = syllable.codaStr
        let stopCodas: Set<String> = ["c", "ch", "p", "t"]
        
        if stopCodas.contains(coda) {
            // Only allow tone 1 (sắc) or 5 (nặng) or 0 (no tone)
            return syllable.tone == 0 || syllable.tone == 1 || syllable.tone == 5
        }
        return true
    }
    
    /// L8: Spelling rules (c/k, g/gh, ng/ngh)
    static func checkSpelling(_ syllable: Syllable) -> Bool {
        let onset = syllable.onsetStr
        let vowels = syllable.vowelsBase
        
        guard !vowels.isEmpty else { return true }
        let firstVowel = vowels[0]
        
        // c/k rule: k before i, e, ê; c before others
        if onset == "k" {
            return ["i", "e", "ê"].contains(firstVowel)
        }
        if onset == "c" && ["i", "e", "ê"].contains(firstVowel) {
            return false  // Should use "k"
        }
        
        // g/gh rule: gh before i, e, ê; g before others
        if onset == "gh" {
            return ["i", "e", "ê"].contains(firstVowel)
        }
        
        // ng/ngh rule: ngh before i, e, ê; ng before others
        if onset == "ngh" {
            return ["i", "e", "ê"].contains(firstVowel)
        }
        if onset == "ng" && ["i", "e", "ê"].contains(firstVowel) {
            return false  // Should use "ngh"
        }
        
        return true
    }
    
    /// L9: Modifier requirements (circumflex for certain patterns)
    static func checkModifierReq(_ syllable: Syllable) -> Bool {
        // This is a simplified check - full implementation would verify
        // that certain vowel combinations require specific modifiers
        return true
    }
    
    // MARK: - Tone Helpers
    
    /// Check if character has a tone mark
    static func hasTone(_ c: Character) -> Bool {
        return getTone(c) != 0
    }
    
    /// Get tone mark (1=sắc, 2=huyền, 3=hỏi, 4=ngã, 5=nặng, 0=none)
    static func getTone(_ c: Character) -> UInt8 {
        let tonedChars: [Character: UInt8] = [
            // Sắc (1)
            "á": 1, "ắ": 1, "ấ": 1, "é": 1, "ế": 1, "í": 1,
            "ó": 1, "ố": 1, "ớ": 1, "ú": 1, "ứ": 1, "ý": 1,
            // Huyền (2)
            "à": 2, "ằ": 2, "ầ": 2, "è": 2, "ề": 2, "ì": 2,
            "ò": 2, "ồ": 2, "ờ": 2, "ù": 2, "ừ": 2, "ỳ": 2,
            // Hỏi (3)
            "ả": 3, "ẳ": 3, "ẩ": 3, "ẻ": 3, "ể": 3, "ỉ": 3,
            "ỏ": 3, "ổ": 3, "ở": 3, "ủ": 3, "ử": 3, "ỷ": 3,
            // Ngã (4)
            "ã": 4, "ẵ": 4, "ẫ": 4, "ẽ": 4, "ễ": 4, "ĩ": 4,
            "õ": 4, "ỗ": 4, "ỡ": 4, "ũ": 4, "ữ": 4, "ỹ": 4,
            // Nặng (5)
            "ạ": 5, "ặ": 5, "ậ": 5, "ẹ": 5, "ệ": 5, "ị": 5,
            "ọ": 5, "ộ": 5, "ợ": 5, "ụ": 5, "ự": 5, "ỵ": 5,
        ]
        return tonedChars[c] ?? 0
    }
}
