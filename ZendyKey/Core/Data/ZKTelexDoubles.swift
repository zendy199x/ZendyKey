//
//  ZKTelexDoubles.swift
//  ZendyKey
//
//  English words containing Telex patterns that should auto-restore.
//  Uses Set for O(1) lookup.
//

import Foundation

/// Telex Doubles - English words with Telex-like patterns
/// When these patterns are detected and the word is in this list,
/// we should restore to English instead of keeping Vietnamese.
class ZKTelexDoubles {
    
    // MARK: - Singleton
    
    static let shared = ZKTelexDoubles()
    
    // MARK: - Data
    
    /// Lazy-loaded Set of words with Telex patterns for O(1) lookup
    private lazy var words: Set<String> = {
        loadWords()
    }()
    
    /// Word count
    var wordCount: Int {
        return words.count
    }
    
    private init() {}
    
    // MARK: - Public API
    
    /// Check if word is in the telex doubles list
    /// These are English words that contain Telex-like patterns (ss, ff, oo, ee, aa, dd)
    /// - Parameter word: The word to check (case-insensitive)
    /// - Returns: True if word is in the list
    func contains(_ word: String) -> Bool {
        return words.contains(word.lowercased())
    }
    
    /// Check binary via sorted array (for compatibility if needed)
    /// - Parameter word: The word to search (case-insensitive)
    /// - Returns: True if word exists in sorted list
    func binarySearch(_ word: String) -> Bool {
        // Set lookup is already O(1), no need for binary search
        return contains(word)
    }
    
    // MARK: - Loading
    
    /// Load words from bundled resource file
    private func loadWords() -> Set<String> {
        var result = Set<String>()
        
        // Try to load from bundle resource
        if let url = Bundle.main.url(forResource: "ZKTelexDoubles", withExtension: "txt"),
           let contents = try? String(contentsOf: url, encoding: .utf8) {
            let lines = contents.components(separatedBy: .newlines)
            for line in lines {
                let word = line.trimmingCharacters(in: .whitespaces)
                if !word.isEmpty {
                    result.insert(word.lowercased())
                }
            }
        } else {
            // Fallback: embed essential words
            let essential = [
                // Double SS words
                "access", "address", "ass", "assess", "bass", "boss", "business",
                "class", "cross", "discuss", "dress", "express", "gross", "guess",
                "issue", "less", "loss", "mass", "mess", "miss", "pass", "password",
                "press", "process", "stress", "success", "across", "unless",
                
                // Double FF words
                "affair", "affect", "afford", "buffalo", "buff", "coffee", "cuff",
                "differ", "different", "difficult", "effect", "effort", "efficient",
                "off", "offer", "office", "officer", "official", "offline", "offspring",
                "puff", "staff", "stuff", "suffer", "sufficient", "traffic",
                
                // Double OO words  
                "book", "blood", "boot", "choose", "cool", "door", "floor",
                "food", "foot", "good", "hood", "look", "loop", "mood", "moon",
                "noon", "pool", "poor", "proof", "room", "root", "school", "smooth",
                "soon", "spoon", "stood", "tool", "too", "took", "wood", "wool",
                
                // Double EE words
                "agree", "bee", "been", "beer", "between", "career", "committee",
                "deep", "deer", "degree", "employee", "engineer", "fee", "feed", "feel",
                "feet", "free", "freedom", "green", "greet", "indeed", "keen", "keep",
                "knee", "meet", "meeting", "need", "oversee", "peer", "proceed",
                "queen", "screen", "see", "seed", "seek", "seem", "seen", "sheep",
                "sheet", "sleep", "speed", "steel", "steer", "street", "succeed",
                "sweet", "teen", "teeth", "three", "tree", "week", "wheel",
                
                // Double AA words
                "aardvark", "baal", "kraal",
                
                // Double DD words
                "add", "added", "addict", "addictive", "addition", "additional",
                "address", "addressed", "addressed", "daddy", "hidden", "ladder",
                "madden", "middle", "muddy", "nodded", "odd", "padded", "reddit",
                "sadden", "sudden", "wedding", "waddle"
            ]
            result = Set(essential)
            ZKDebugLogger.shared.warning("Could not load telex_doubles.txt, using fallback list", source: "TelexDoubles")
        }
        
        ZKDebugLogger.shared.info("Loaded \(result.count) telex doubles words", source: "TelexDoubles")
        return result
    }
}
