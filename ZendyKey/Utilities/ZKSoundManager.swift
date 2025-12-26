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
    
    // System sounds
    private let toggleOnSound = NSSound(named: "Pop")
    private let toggleOffSound = NSSound(named: "Tink")
    private let typeClickSound = NSSound(named: "Morse")
    
    private init() {
        // Volume is now dynamically read from preferences
    }
    
    // MARK: - Public Methods
    
    /// Play toggle sound based on the new state
    func playToggleSound(enabled: Bool) {
        guard isSoundEnabled else { return }
        
        let currentVolume = volume
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            if enabled {
                self?.toggleOnSound?.volume = currentVolume
                self?.toggleOnSound?.play()
            } else {
                self?.toggleOffSound?.volume = currentVolume
                self?.toggleOffSound?.play()
            }
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
