//
//  ZKSoundManager.swift
//  ZendyKey
//
//  Sound Manager for toggle sounds and system feedback
//

import AppKit
import AVFoundation

/// Manages sound effects for the application
class ZKSoundManager {
    static let shared = ZKSoundManager()
    
    // Sound enabled state (read from ZKSharedSettings for consistency with preferences)
    var isSoundEnabled: Bool {
        get { ZKSharedSettings.shared.beepOnToggle }
        set { ZKSharedSettings.shared.beepOnToggle = newValue }
    }
    
    // Volume control - reads from preferences
    var volume: Float {
        Float(ZKSharedSettings.shared.beepVolume)
    }
    
    // System sounds - cached to prevent issues with rapid toggling
    private let toggleOnSound = NSSound(named: "Pop")
    private let toggleOffSound = NSSound(named: "Tink")
    private let typeClickSound = NSSound(named: "Morse")
    private var currentSound: NSSound?
    
    private init() {
        // Volume is now dynamically read from preferences
    }
    
    // MARK: - Public Methods
    
    /// Play toggle sound based on the new state
    func playToggleSound(enabled: Bool) {
        guard isSoundEnabled else { return }
        
        // Stop any currently playing sound to handle rapid toggling
        currentSound?.stop()
        
        let currentVolume = volume
        let sound = enabled ? toggleOnSound : toggleOffSound
        currentSound = sound
        
        DispatchQueue.global(qos: .userInteractive).async {
            sound?.volume = currentVolume
            sound?.play()
        }
    }
    
    /// Play a subtle click sound for key presses (optional feature)
    func playTypeClick() {
        guard isSoundEnabled else { return }
        
        let currentVolume = volume * 0.3  // Type clicks should be quieter
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.typeClickSound?.volume = currentVolume
            self?.typeClickSound?.play()
        }
    }
    
    /// Play success sound
    func playSuccess() {
        guard isSoundEnabled else { return }
        
        DispatchQueue.global(qos: .userInteractive).async {
            NSSound.beep() // Simple beep for success feedback
        }
    }
    
    /// Play system alert
    func playAlert() {
        guard isSoundEnabled else { return }
        
        DispatchQueue.global(qos: .userInteractive).async {
            NSSound.beep()
        }
    }
}

// MARK: - Haptic Feedback (if available)

extension ZKSoundManager {
    /// Provide haptic feedback if available (for MacBooks with Force Touch)
    @available(macOS 10.11, *)
    func performHaptic() {
        // Note: NSHapticFeedbackManager is available but limited on macOS
        // This is a placeholder for future haptic support
        #if os(macOS)
        if #available(macOS 10.11, *) {
            NSHapticFeedbackManager.defaultPerformer.perform(
                .alignment,
                performanceTime: .default
            )
        }
        #endif
    }
}
