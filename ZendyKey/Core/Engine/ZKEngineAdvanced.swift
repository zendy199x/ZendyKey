//
//  ZKEngineAdvanced.swift
//  ZendyKey
//
//  Advanced features implementation for ZKEngine
//  Ported from OpenKey Engine.cpp
//

import Foundation

extension ZKEngine {
    
    // MARK: - Quick Telex
    
    /// Handle Quick Telex conversion (cc→ch, gg→gi, etc.)
    func handleQuickTelex(keyCode: UInt16, isCaps: Bool) {
        guard index > 0 else {
            insertKey(keyCode: keyCode, isCaps: isCaps)
            return
        }
        
        // Quick Telex mappings:
        // cc → ch, gg → gi, kk → kh, nn → ng
        // pp → ph, qq → qu, tt → th
        
        var replacementKey: UInt16 = 0
        
        switch keyCode {
        case ZKVietnameseData.KEY_C:
            replacementKey = ZKVietnameseData.KEY_H  // cc → ch
        case ZKVietnameseData.KEY_G:
            replacementKey = ZKVietnameseData.KEY_I  // gg → gi
        case ZKVietnameseData.KEY_K:
            replacementKey = ZKVietnameseData.KEY_H  // kk → kh
        case ZKVietnameseData.KEY_N:
            replacementKey = ZKVietnameseData.KEY_G  // nn → ng
        case ZKVietnameseData.KEY_P:
            replacementKey = ZKVietnameseData.KEY_H  // pp → ph
        case ZKVietnameseData.KEY_Q:
            replacementKey = ZKVietnameseData.KEY_U  // qq → qu
        case ZKVietnameseData.KEY_T:
            replacementKey = ZKVietnameseData.KEY_H  // tt → th
        default:
            insertKey(keyCode: keyCode, isCaps: isCaps)
            return
        }
        
        // Insert the replacement key
        hookState.code = UInt8(vWillProcess)
        hookState.backspaceCount = 0
        hookState.newCharCount = 1
        
        // Set the new character
        setKeyData(index: index, keyCode: replacementKey, isCaps: isCaps)
        index += 1
        
        // Return the character to send
        hookState.charData[0] = getCharacterCode(typingWord[Int(index) - 1])
        
        logCallback?("Quick Telex: \(keyCode)\(keyCode) → \(keyCode)\(replacementKey)")
    }
    
    // MARK: - Quick Consonant
    
    /// Check and handle Quick Start/End Consonant
    func checkQuickConsonant() {
        hasHandleQuickConsonant = false
        
        guard index > 0 else { return }
        
        // Quick Start Consonant: f→ph, j→gi, w→qu
        if vQuickStartConsonant == 1 && index >= 1 {
            let firstKey = chr(0)
            var replacement: (UInt16, UInt16)? = nil
            
            switch firstKey {
            case ZKVietnameseData.KEY_F:
                replacement = (ZKVietnameseData.KEY_P, ZKVietnameseData.KEY_H)  // f → ph
            case ZKVietnameseData.KEY_J:
                replacement = (ZKVietnameseData.KEY_G, ZKVietnameseData.KEY_I)  // j → gi
            case ZKVietnameseData.KEY_W:
                replacement = (ZKVietnameseData.KEY_Q, ZKVietnameseData.KEY_U)  // w → qu
            default:
                break
            }
            
            if let (first, second) = replacement {
                // Replace first character and insert second
                let isCaps = (typingWord[0] & ZKEngine.CAPS_MASK) != 0
                
                // Shift all characters right by 1
                for i in stride(from: Int(index), through: 1, by: -1) {
                    typingWord[i] = typingWord[i - 1]
                }
                
                // Set new characters
                typingWord[0] = UInt32(first) | (isCaps ? ZKEngine.CAPS_MASK : 0)
                typingWord[1] = UInt32(second) | (isCaps ? ZKEngine.CAPS_MASK : 0)
                index += 1
                
                // Set hook state to send backspaces and new characters
                hookState.code = UInt8(vWillProcess)
                hookState.backspaceCount = Int(index)
                hookState.newCharCount = Int(index)
                
                for i in 0..<Int(index) {
                    hookState.charData[Int(index) - 1 - i] = getCharacterCode(typingWord[i])
                }
                
                hasHandleQuickConsonant = true
                logCallback?("Quick Start Consonant: \(firstKey) → \(first)\(second)")
                return
            }
        }
        
        // Quick End Consonant: g→ng, h→nh, k→ch
        if vQuickEndConsonant == 1 && index >= 2 {
            let lastKey = chr(Int(index) - 1)
            var replacement: (UInt16, UInt16)? = nil
            
            // Only apply if previous char is a vowel
            let prevKey = chr(Int(index) - 2)
            let isVowel = !vietnameseData.isConsonant(prevKey)
            
            if isVowel {
                switch lastKey {
                case ZKVietnameseData.KEY_G:
                    replacement = (ZKVietnameseData.KEY_N, ZKVietnameseData.KEY_G)  // g → ng
                case ZKVietnameseData.KEY_H:
                    replacement = (ZKVietnameseData.KEY_N, ZKVietnameseData.KEY_H)  // h → nh
                case ZKVietnameseData.KEY_K:
                    replacement = (ZKVietnameseData.KEY_C, ZKVietnameseData.KEY_H)  // k → ch
                default:
                    break
                }
            }
            
            if let (first, second) = replacement {
                let isCaps = (typingWord[Int(index) - 1] & ZKEngine.CAPS_MASK) != 0
                
                // Replace last character with two characters
                typingWord[Int(index) - 1] = UInt32(first) | (isCaps ? ZKEngine.CAPS_MASK : 0)
                typingWord[Int(index)] = UInt32(second) | (isCaps ? ZKEngine.CAPS_MASK : 0)
                index += 1
                
                // Set hook state
                hookState.code = UInt8(vWillProcess)
                hookState.backspaceCount = 1
                hookState.newCharCount = 2
                
                hookState.charData[0] = getCharacterCode(typingWord[Int(index) - 1])
                hookState.charData[1] = getCharacterCode(typingWord[Int(index) - 2])
                
                hasHandleQuickConsonant = true
                logCallback?("Quick End Consonant: \(lastKey) → \(first)\(second)")
            }
        }
    }
    
    // MARK: - Upper Case First Character
    
    /// Auto capitalize first character after sentence end
    func upperCaseFirstCharacter() {
        guard index >= 1 else { return }
        
        // Check if first character is lowercase
        let firstChar = typingWord[0]
        let keyCode = UInt16(firstChar & ZKEngine.CHAR_MASK)
        
        // Only capitalize if it's a letter and not already uppercase
        guard vietnameseData.isLetter(keyCode) else { return }
        guard (firstChar & ZKEngine.CAPS_MASK) == 0 else { return }
        
        // Set uppercase flag
        typingWord[0] |= ZKEngine.CAPS_MASK
        
        // Update hook state to send the change
        hookState.code = UInt8(vWillProcess)
        hookState.backspaceCount = Int(index)
        hookState.newCharCount = Int(index)
        
        for i in 0..<Int(index) {
            hookState.charData[Int(index) - 1 - i] = getCharacterCode(typingWord[i])
        }
        
        logCallback?("Upper Case First Char: Applied to first character")
    }
    
    // MARK: - Restore If Wrong Spelling
    
    /// Check and restore if word has wrong spelling
    @discardableResult
    func checkRestoreIfWrongSpelling(handleCode: Int) -> Bool {
        guard tempDisableKey else { return false }
        guard index > 0 else { return false }
        
        // Get original typed keys from keyStates
        var originalWord = [UInt32]()
        for i in 0..<Int(stateIndex) {
            originalWord.append(keyStates[i])
        }
        
        guard !originalWord.isEmpty else { return false }
        
        // Calculate backspaces needed
        hookState.code = UInt8(handleCode)
        hookState.backspaceCount = Int(index)
        hookState.newCharCount = originalWord.count
        
        // Set original characters to send
        for i in 0..<originalWord.count {
            let keyData = originalWord[i]
            let keyCode = UInt16(keyData & ZKEngine.CHAR_MASK)
            let isCaps = (keyData & ZKEngine.CAPS_MASK) != 0
            
            // Convert to character code
            var charCode = UInt32(keyCode)
            if isCaps {
                charCode |= ZKEngine.CAPS_MASK
            }
            hookState.charData[originalWord.count - 1 - i] = charCode
        }
        
        logCallback?("Restore Wrong Spelling: Restoring \(originalWord.count) characters")
        
        // Reset state
        if handleCode == vRestoreAndStartNewSession {
            startNewSession()
        }
        
        return true
    }
}
