//
//  ZKTonePlacement.swift
//  ZendyKey
//
//  Pattern-based tone placement for Vietnamese.
//

import Foundation

/// Pattern-based tone placement for Vietnamese syllables.
/// Uses lookup tables instead of hardcoded logic for maintainability.
struct ZKTonePlacement {
    
    // MARK: - Vowel Info
    
    /// Information about a vowel in the buffer
    struct VowelInfo: Equatable {
        let position: Int       // Character index in buffer
        let vowel: Character    // Base vowel (lowercase, no tone)
        let hasModifier: Bool   // Has circumflex/horn/breve
    }
    
    /// Context for placement decisions
    struct PlacementContext {
        var hasQuInitial: Bool = false   // Buffer starts with "qu"
        var hasGiInitial: Bool = false   // Buffer starts with "gi"
        var useModern: Bool = true       // Modern style: hoà, uý (vs traditional: hòa, úy)
    }
    
    // MARK: - Pattern Tables
    
    /// Diphthongs with tone on FIRST vowel (main + glide patterns)
    /// These ALWAYS get mark on first vowel regardless of final consonant
    static let toneFirstPatterns: [[Character]] = [
        ["a", "i"],  // ai: mái, hài
        ["a", "o"],  // ao: cáo, sào
        ["a", "u"],  // au: sáu, màu
        ["a", "y"],  // ay: máy, tày
        ["e", "o"],  // eo: kéo, trèo
        ["ê", "u"],  // êu: nếu, kêu
        ["i", "a"],  // ia: kìa, mía (NOT after gi-initial)
        ["i", "u"],  // iu: dịu, kíu
        ["o", "i"],  // oi: đói, còi
        ["u", "i"],  // ui: túi, mùi
        ["ư", "u"],  // ưu: lưu, hưu
    ]
    
    /// Diphthongs with tone on SECOND vowel (medial + main, compound patterns)
    static let toneSecondPatterns: [[Character]] = [
        ["o", "a"],  // oa: hoà, toá
        ["o", "e"],  // oe: khoẻ, xoè
        ["u", "ê"],  // uê: huế, tuệ
        ["u", "y"],  // uy: quý, thuỳ
        ["i", "ê"],  // iê: tiên, biết (compound)
        ["u", "ô"],  // uô: cuối, muốn (compound)
        ["ư", "ơ"],  // ươ: được, nước (compound)
    ]
    
    /// Triphthong patterns with tone position (0=first, 1=middle, 2=last)
    static let triphthongPatterns: [([Character], Int)] = [
        (["i", "ê", "u"], 1),  // iêu: tiếu (middle = ê)
        (["y", "ê", "u"], 1),  // yêu: yếu (middle = ê)
        (["o", "a", "i"], 1),  // oai: ngoài (middle = a)
        (["o", "a", "y"], 1),  // oay: xoáy (middle = a)
        (["o", "e", "o"], 1),  // oeo: khoèo (middle = e)
        (["u", "â", "y"], 1),  // uây: khuấy (middle = â)
        (["u", "ô", "i"], 1),  // uôi: cuối (middle = ô)
        (["ư", "ơ", "i"], 1),  // ươi: mười (middle = ơ)
        (["ư", "ơ", "u"], 1),  // ươu: rượu (middle = ơ)
        (["u", "y", "ê"], 2),  // uyê: khuyến, quyền (LAST = ê)
    ]
    
    /// Vowels with modifiers (circumflex, horn, breve)
    static let modifiedVowels: Set<Character> = ["â", "ê", "ô", "ơ", "ư", "ă"]
    
    // MARK: - Main API
    
    /// Find the position where tone should be placed
    /// - Parameters:
    ///   - vowels: Array of VowelInfo for vowels in buffer
    ///   - hasFinal: Whether buffer has a final consonant
    ///   - context: Placement context (qu/gi-initial, modern style)
    /// - Returns: Position index (in buffer) where tone should be placed, or nil
    static func findTonePosition(
        vowels: [VowelInfo],
        hasFinal: Bool,
        context: PlacementContext = PlacementContext()
    ) -> Int? {
        // Handle gi-initial: first 'i' is part of consonant, skip it
        var effectiveVowels = vowels
        if context.hasGiInitial && !vowels.isEmpty && vowels[0].vowel == "i" {
            effectiveVowels = Array(vowels.dropFirst())
        }
        // Handle qu-initial: first 'u' is part of consonant, skip it
        else if context.hasQuInitial && !vowels.isEmpty && vowels[0].vowel == "u" {
            effectiveVowels = Array(vowels.dropFirst())
        }
        
        switch effectiveVowels.count {
        case 0:
            return nil
            
        case 1:
            // Single vowel: place tone on it
            return effectiveVowels[0].position
            
        case 2:
            return findDiphthongPosition(effectiveVowels, hasFinal: hasFinal, context: context)
            
        case 3...:
            return findTriphthongPosition(effectiveVowels, hasFinal: hasFinal, context: context)
            
        default:
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    private static func findDiphthongPosition(
        _ vowels: [VowelInfo],
        hasFinal: Bool,
        context: PlacementContext
    ) -> Int? {
        guard vowels.count >= 2 else { return vowels.first?.position }
        
        let v1 = vowels[0].vowel
        let v2 = vowels[1].vowel
        let pair = [v1, v2]
        
        // Check TONE_FIRST patterns (always first vowel)
        if toneFirstPatterns.contains(where: { $0 == pair }) {
            return vowels[0].position
        }
        
        // Modern/Traditional style for oa, oe, uy patterns
        if context.useModern {
            // Modern: tone on second vowel
            if toneSecondPatterns.contains(where: { $0 == pair }) {
                return vowels[1].position
            }
        } else {
            // Traditional: oa, oe, uy → tone on first vowel (unless has final)
            if (pair == ["o", "a"] || pair == ["o", "e"] || pair == ["u", "y"]) && !hasFinal {
                return vowels[0].position
            }
            // With final consonant, use second vowel
            if toneSecondPatterns.contains(where: { $0 == pair }) {
                return vowels[1].position
            }
        }
        
        // Modifier preference: vowel with modifier gets priority
        if vowels[0].hasModifier && !vowels[1].hasModifier {
            return vowels[0].position
        }
        if vowels[1].hasModifier && !vowels[0].hasModifier {
            return vowels[1].position
        }
        
        // Default: with final → first, without final → second
        return hasFinal ? vowels[0].position : vowels[1].position
    }
    
    private static func findTriphthongPosition(
        _ vowels: [VowelInfo],
        hasFinal: Bool,
        context: PlacementContext
    ) -> Int? {
        guard vowels.count >= 3 else { return findDiphthongPosition(vowels, hasFinal: hasFinal, context: context) }
        
        let triplet = [vowels[0].vowel, vowels[1].vowel, vowels[2].vowel]
        
        // Check triphthong patterns
        for (pattern, position) in triphthongPatterns {
            if pattern == triplet {
                return vowels[position].position
            }
        }
        
        // Default: middle vowel
        return vowels[1].position
    }
    
    // MARK: - Utility
    
    /// Get base vowel (strip tones)
    static func getBaseVowel(_ char: Character) -> Character {
        let mapping: [Character: Character] = [
            // A variants
            "á": "a", "à": "a", "ả": "a", "ã": "a", "ạ": "a",
            "ắ": "ă", "ằ": "ă", "ẳ": "ă", "ẵ": "ă", "ặ": "ă",
            "ấ": "â", "ầ": "â", "ẩ": "â", "ẫ": "â", "ậ": "â",
            // E variants
            "é": "e", "è": "e", "ẻ": "e", "ẽ": "e", "ẹ": "e",
            "ế": "ê", "ề": "ê", "ể": "ê", "ễ": "ê", "ệ": "ê",
            // I variants
            "í": "i", "ì": "i", "ỉ": "i", "ĩ": "i", "ị": "i",
            // O variants
            "ó": "o", "ò": "o", "ỏ": "o", "õ": "o", "ọ": "o",
            "ố": "ô", "ồ": "ô", "ổ": "ô", "ỗ": "ô", "ộ": "ô",
            "ớ": "ơ", "ờ": "ơ", "ở": "ơ", "ỡ": "ơ", "ợ": "ơ",
            // U variants
            "ú": "u", "ù": "u", "ủ": "u", "ũ": "u", "ụ": "u",
            "ứ": "ư", "ừ": "ư", "ử": "ư", "ữ": "ư", "ự": "ư",
            // Y variants
            "ý": "y", "ỳ": "y", "ỷ": "y", "ỹ": "y", "ỵ": "y",
        ]
        
        return mapping[char] ?? char.lowercased().first ?? char
    }
    
    /// Check if character is a Vietnamese vowel
    static func isVowel(_ char: Character) -> Bool {
        let lower = char.lowercased().first ?? char
        let baseVowels: Set<Character> = ["a", "ă", "â", "e", "ê", "i", "o", "ô", "ơ", "u", "ư", "y"]
        return baseVowels.contains(lower) || baseVowels.contains(getBaseVowel(char))
    }
    
    /// Check if vowel has a modifier (circumflex, horn, or breve)
    static func hasModifier(_ char: Character) -> Bool {
        return modifiedVowels.contains(getBaseVowel(char))
    }
}
