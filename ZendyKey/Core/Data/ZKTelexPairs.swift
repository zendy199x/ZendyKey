//
//  ZKTelexPairs.swift
//  ZendyKey
//
//  Telex input → Vietnamese output pairs for validation and testing.
//  Contains 27k pairs from gonhanh.org test data.
//  Format: "telex_input\texpected_output"
//

import Foundation

/// Telex transformation pairs for validation
/// Used to verify engine behavior and for unit testing
class ZKTelexPairs {
    
    // MARK: - Singleton
    
    static let shared = ZKTelexPairs()
    
    // MARK: - Data Structure
    
    /// Pair of telex input → expected Vietnamese output
    struct TelexPair {
        let input: String    // Raw telex input (e.g., "viet")
        let output: String   // Expected Vietnamese output (e.g., "việt")
    }
    
    // MARK: - Data
    
    /// Lazy-loaded array of telex pairs
    private lazy var pairs: [TelexPair] = {
        loadPairs()
    }()
    
    /// Dictionary for O(1) lookup: telex → vietnamese
    private lazy var lookupTable: [String: String] = {
        var table = [String: String]()
        for pair in pairs {
            table[pair.input.lowercased()] = pair.output
        }
        return table
    }()
    
    /// Pair count
    var pairCount: Int {
        return pairs.count
    }
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get expected Vietnamese output for a telex input
    /// - Parameter telexInput: The telex input string
    /// - Returns: Expected Vietnamese output, or nil if not found
    func getExpectedOutput(for telexInput: String) -> String? {
        return lookupTable[telexInput.lowercased()]
    }
    
    /// Check if a telex→output transformation is valid
    /// - Parameters:
    ///   - telexInput: The telex input
    ///   - actualOutput: The actual output from engine
    /// - Returns: True if transformation matches expected output
    func isValidTransformation(_ telexInput: String, actualOutput: String) -> Bool {
        guard let expected = getExpectedOutput(for: telexInput) else {
            return true // Not in our test data, assume valid
        }
        return expected.lowercased() == actualOutput.lowercased()
    }
    
    /// Get all pairs for testing
    func getAllPairs() -> [TelexPair] {
        return pairs
    }
    
    /// Get subset of pairs for quick testing
    /// - Parameter count: Number of pairs to return
    func getTestSubset(count: Int = 100) -> [TelexPair] {
        return Array(pairs.prefix(count))
    }
    
    // MARK: - Loading
    
    private func loadPairs() -> [TelexPair] {
        var result: [TelexPair] = []
        
        // Load from bundle resource
        if let url = Bundle.main.url(forResource: "ZKTelexPairs", withExtension: "txt"),
           let contents = try? String(contentsOf: url, encoding: .utf8) {
            let lines = contents.components(separatedBy: .newlines)
            for line in lines {
                let parts = line.components(separatedBy: "\t")
                if parts.count >= 2 {
                    let input = parts[0].trimmingCharacters(in: .whitespaces)
                    let output = parts[1].trimmingCharacters(in: .whitespaces)
                    if !input.isEmpty && !output.isEmpty {
                        result.append(TelexPair(input: input, output: output))
                    }
                }
            }
        } else {
            // Fallback: common telex pairs
            let common: [(String, String)] = [
                ("viet", "việt"), ("nam", "nam"), ("xin", "xin"), ("chao", "chào"),
                ("cam", "cảm"), ("on", "ơn"), ("khong", "không"), ("co", "có"),
                ("ddis", "đi"), ("dden", "đến"), ("vef", "về"), ("len", "lên"),
                ("xuoongs", "xuống"), ("vaof", "vào"), ("ra", "ra")
            ]
            result = common.map { TelexPair(input: $0.0, output: $0.1) }
            ZKDebugLogger.shared.warning("Could not load zk_telex_pairs.txt, using fallback", source: "TelexPairs")
        }
        
        ZKDebugLogger.shared.info("Loaded \(result.count) telex pairs", source: "TelexPairs")
        return result
    }
}
