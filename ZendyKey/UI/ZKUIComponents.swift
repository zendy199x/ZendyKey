//
//  ZKUIComponents.swift
//  ZendyKey
//
//  Reusable UI Components inspired by GoNhanh
//  Note: VisualEffectBackground is defined in ZKDesignSystem.swift
//

import SwiftUI
import AppKit

// MARK: - Settings Toggle Row with Subtitle

/// A toggle row with title, optional subtitle, and description
struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    let description: String?
    @Binding var isOn: Bool
    
    init(title: String, subtitle: String? = nil, description: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self._isOn = isOn
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
    }
}

// MARK: - Card Background View Modifier

struct CardBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat
    
    init(cornerRadius: CGFloat = 12, padding: CGFloat = 16) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
            )
    }
}

extension View {
    /// Apply card background with consistent styling
    func cardBackground(cornerRadius: CGFloat = 12, padding: CGFloat = 16) -> some View {
        modifier(CardBackgroundModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - KeyCap View

/// Displays a keyboard key cap for shortcut display
struct KeyCap: View {
    let key: String
    let isModifier: Bool
    
    init(_ key: String, isModifier: Bool = false) {
        self.key = key
        self.isModifier = isModifier
    }
    
    private var displayKey: String {
        // Convert common modifier symbols
        switch key.lowercased() {
        case "cmd", "command", "⌘": return "⌘"
        case "ctrl", "control", "⌃": return "⌃"
        case "opt", "option", "alt", "⌥": return "⌥"
        case "shift", "⇧": return "⇧"
        case "space": return "␣"
        case "return", "enter", "↩": return "↩"
        case "tab", "⇥": return "⇥"
        case "esc", "escape": return "⎋"
        case "delete", "backspace", "⌫": return "⌫"
        default: return key.uppercased()
        }
    }
    
    var body: some View {
        Text(displayKey)
            .font(.system(size: isModifier ? 12 : 11, weight: .medium, design: .rounded))
            .foregroundColor(.primary)
            .padding(.horizontal, isModifier ? 4 : 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

/// Display a keyboard shortcut as a row of key caps
struct ShortcutDisplay: View {
    let modifiers: [String]
    let key: String?
    
    init(modifiers: [String], key: String? = nil) {
        self.modifiers = modifiers
        self.key = key
    }
    
    init(hotkey: Hotkey) {
        var mods: [String] = []
        if hotkey.modifiers.contains(.control) { mods.append("⌃") }
        if hotkey.modifiers.contains(.option) { mods.append("⌥") }
        if hotkey.modifiers.contains(.shift) { mods.append("⇧") }
        if hotkey.modifiers.contains(.command) { mods.append("⌘") }
        self.modifiers = mods
        
        if hotkey.isModifierOnly {
            self.key = nil
        } else {
            // Convert keyCode to character
            let mapping: [UInt16: String] = [
                0x00: "A", 0x0B: "B", 0x08: "C", 0x02: "D", 0x0E: "E",
                0x03: "F", 0x05: "G", 0x04: "H", 0x22: "I", 0x26: "J",
                0x28: "K", 0x25: "L", 0x2E: "M", 0x2D: "N", 0x1F: "O",
                0x23: "P", 0x0C: "Q", 0x0F: "R", 0x01: "S", 0x11: "T",
                0x20: "U", 0x09: "V", 0x0D: "W", 0x07: "X", 0x10: "Y",
                0x06: "Z", 0x31: "Space"
            ]
            self.key = mapping[hotkey.keyCode]
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(modifiers, id: \.self) { mod in
                KeyCap(mod, isModifier: true)
            }
            if let key = key {
                KeyCap(key)
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String?
    
    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Animated Checkmark

struct AnimatedCheckmark: View {
    let isChecked: Bool
    
    var body: some View {
        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 20))
            .foregroundColor(isChecked ? .green : .secondary.opacity(0.4))
            .animation(.spring(response: 0.3), value: isChecked)
    }
}

// MARK: - Step Indicator

/// Step indicator dots for onboarding/wizard flows
struct StepIndicator: View {
    let totalSteps: Int
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ZKUIComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // SettingsToggleRow
            SettingsToggleRow(
                title: "Enable Feature",
                subtitle: "This is a subtitle",
                description: "This is a longer description that explains what the feature does.",
                isOn: .constant(true)
            )
            .cardBackground()
            
            // KeyCap and ShortcutDisplay
            HStack {
                KeyCap("⌘", isModifier: true)
                KeyCap("⇧", isModifier: true)
                KeyCap("V")
            }
            
            ShortcutDisplay(modifiers: ["⌘", "⇧"], key: "V")
            
            // StepIndicator
            StepIndicator(totalSteps: 4, currentStep: 1)
        }
        .padding()
        .frame(width: 400)
    }
}
#endif
