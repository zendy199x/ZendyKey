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
    
    // Volume control (0.0 to 1.0)
    var volume: Float = 0.5
    
    // System sounds
    private let toggleOnSound = NSSound(named: "Pop")
    private let toggleOffSound = NSSound(named: "Tink")
    private let typeClickSound = NSSound(named: "Morse")
    
    private init() {
        // Set default volume for all sounds
        toggleOnSound?.volume = volume
        toggleOffSound?.volume = volume
        typeClickSound?.volume = volume * 0.3 // Type clicks should be quieter
    }
    
    // MARK: - Public Methods
    
    /// Play toggle sound based on the new state
    func playToggleSound(enabled: Bool) {
        guard isSoundEnabled else { return }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            if enabled {
                self?.toggleOnSound?.play()
            } else {
                self?.toggleOffSound?.play()
            }
        }
    }
    
    /// Play a subtle click sound for key presses (optional feature)
    func playTypeClick() {
        guard isSoundEnabled else { return }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
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
    
    /// Update volume for all sounds
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
        toggleOnSound?.volume = volume
        toggleOffSound?.volume = volume
        typeClickSound?.volume = volume * 0.3
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
