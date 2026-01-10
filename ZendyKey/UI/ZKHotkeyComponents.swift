//
//  ZKHotkeyComponents.swift
//  ZendyKey
//
//  Reusable hotkey configuration components
//  ModifierKeyButton, PauseKeyButton, PauseKeyConfigSection
//

import SwiftUI
import AppKit

// MARK: - Modifier Key Button (Toggle Style)

/// A styled toggle button for modifier key selection
struct ZKModifierKeyButton: View {
    let symbol: String
    let name: String
    @Binding var isOn: Bool
    
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            withAnimation(ZKAnimations.spring) {
                isOn.toggle()
            }
        }) {
            VStack(spacing: 6) {
                Text(symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isOn ? .white : ZKColors.textPrimary)

                Text(name)
                    .font(.caption2)
                    .foregroundColor(isOn ? .white.opacity(0.9) : ZKColors.textSecondary)
            }
            .frame(width: 70, height: 56)
            .background {
                if isOn {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ZKColors.accentGradient)
                        .shadow(color: ZKColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ZKColors.glassBackground)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isOn ? Color.clear : ZKColors.glassBorder, lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : (isOn ? 1.0 : 0.98))
        }
        .buttonStyle(.plain)
        .animation(ZKAnimations.spring, value: isOn)
        .animation(ZKAnimations.springFast, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Pause Key Button (Radio Style)

/// A styled radio button for pause key selection
struct ZKPauseKeyButton: View {
    let symbol: String
    let name: String
    let keyCode: UInt16
    @Binding var selectedKeyCode: UInt16
    @Binding var selectedKeyName: String
    
    @State private var isHovered = false

    private var isSelected: Bool {
        selectedKeyCode == keyCode
    }

    var body: some View {
        Button(action: {
            withAnimation(ZKAnimations.spring) {
                selectedKeyCode = keyCode
                selectedKeyName = name
            }
        }) {
            VStack(spacing: 6) {
                Text(symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .white : ZKColors.textPrimary)

                Text(name)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : ZKColors.textSecondary)
            }
            .frame(width: 70, height: 56)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ZKColors.accentGradient)
                        .shadow(color: ZKColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ZKColors.glassBackground)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : ZKColors.glassBorder, lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : (isSelected ? 1.0 : 0.98))
        }
        .buttonStyle(.plain)
        .animation(ZKAnimations.spring, value: isSelected)
        .animation(ZKAnimations.springFast, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Restore Key Button (Radio Style)

/// A styled radio button for restore key selection
struct ZKRestoreKeyButton: View {
    let symbol: String
    let name: String
    let restoreKey: RestoreKey
    @Binding var selectedKey: RestoreKey
    
    @State private var isHovered = false

    private var isSelected: Bool {
        selectedKey == restoreKey
    }

    var body: some View {
        Button(action: {
            withAnimation(ZKAnimations.spring) {
                selectedKey = restoreKey
            }
        }) {
            VStack(spacing: 6) {
                Text(symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : ZKColors.textPrimary)

                Text(name)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : ZKColors.textSecondary)
            }
            .frame(width: 65, height: 52)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ZKColors.accentGradient)
                        .shadow(color: ZKColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ZKColors.glassBackground)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : ZKColors.glassBorder, lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : (isSelected ? 1.0 : 0.98))
        }
        .buttonStyle(.plain)
        .animation(ZKAnimations.spring, value: isSelected)
        .animation(ZKAnimations.springFast, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Pause Key Configuration Section (Tạm tắt gõ tiếng Việt)

struct ZKPauseKeyConfigSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel

    // Get list of conflicting sections for display
    private var conflictingSections: [String] {
        guard viewModel.preferences.pauseKeyEnabled else { return [] }
        var conflicts: [String] = []
        
        // Check conflict with restore key
        if viewModel.preferences.restoreOnEscape && 
           viewModel.preferences.pauseKey == viewModel.preferences.restoreKey.rawValue {
            conflicts.append("Phím khôi phục nguyên gốc")
        }
        
        // Check conflict with temp off spelling
        if viewModel.preferences.tempOffSpellingEnabled && 
           viewModel.preferences.pauseKey == viewModel.preferences.tempOffSpellingKey {
            conflicts.append("Phím tạm tắt chính tả")
        }
        
        return conflicts
    }

    var body: some View {
        ZKSection("Phím tạm tắt gõ tiếng Việt") {
            VStack(alignment: .leading, spacing: 16) {
                // Enable toggle with icon
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ZKColors.accent.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: "pause.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ZKColors.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bật tính năng tạm tắt gõ tiếng Việt")
                            .font(ZKTypography.body)
                            .foregroundColor(ZKColors.textPrimary)

                        Text("Giữ phím để tạm thời gõ tiếng Anh")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.preferences.pauseKeyEnabled.animation(ZKAnimations.spring))
                        .labelsHidden()
                        .toggleStyle(ZKToggleStyle())
                }

                if viewModel.preferences.pauseKeyEnabled {
                    Divider()
                        .padding(.top, 4)

                    // Key Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chọn phím tạm tắt gõ tiếng Việt")
                            .font(ZKTypography.caption.bold())
                            .foregroundColor(ZKColors.textPrimary)

                        HStack(spacing: 12) {
                            ZKPauseKeyButton(
                                symbol: "⌃",
                                name: "Control",
                                keyCode: 59,
                                selectedKeyCode: $viewModel.preferences.pauseKey,
                                selectedKeyName: $viewModel.preferences.pauseKeyName
                            )
                            ZKPauseKeyButton(
                                symbol: "⌥",
                                name: "Option",
                                keyCode: 58,
                                selectedKeyCode: $viewModel.preferences.pauseKey,
                                selectedKeyName: $viewModel.preferences.pauseKeyName
                            )
                        }

                        Text("Mặc định: Control (⌃). Ví dụ: giữ ⌃ gõ \"email\" → thả ⌃")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textTertiary)
                    }
                    .transition(.opacity)

                    // Comprehensive conflict warning
                    if !conflictingSections.isEmpty {
                        ZKConflictWarningView(message: "Phím đang trùng với: \(conflictingSections.joined(separator: ", "))")
                    }
                }
            }
            .animation(ZKAnimations.spring, value: viewModel.preferences.pauseKeyEnabled)
            .onChange(of: viewModel.preferences.pauseKeyEnabled) { _ in
                viewModel.userDidInteractWithHotkeySection()
            }
            .onChange(of: viewModel.preferences.pauseKey) { _ in
                viewModel.userDidInteractWithHotkeySection()
            }
        }
    }
}

// MARK: - Restore Key Configuration Section

struct ZKRestoreKeyConfigSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel

    // Get list of conflicting sections for display
    private var conflictingSections: [String] {
        guard viewModel.preferences.restoreOnEscape else { return [] }
        var conflicts: [String] = []
        
        // Check conflict with pause key (Tạm tắt gõ tiếng Việt)
        if viewModel.preferences.pauseKeyEnabled && 
           viewModel.preferences.restoreKey.rawValue == viewModel.preferences.pauseKey {
            conflicts.append("Phím tạm tắt gõ tiếng Việt")
        }
        
        // Check conflict with temp off spelling
        if viewModel.preferences.tempOffSpellingEnabled && 
           viewModel.preferences.restoreKey.rawValue == viewModel.preferences.tempOffSpellingKey {
            conflicts.append("Phím tạm tắt chính tả")
        }
        
        return conflicts
    }

    var body: some View {
        ZKSection("Phím khôi phục nguyên gốc") {
            VStack(alignment: .leading, spacing: 16) {
                // Enable toggle
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ZKColors.accent.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ZKColors.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bật khôi phục nguyên gốc")
                            .font(ZKTypography.body)
                            .foregroundColor(ZKColors.textPrimary)

                        Text("Nhấn phím để khôi phục từ về dạng chưa có dấu")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.preferences.restoreOnEscape.animation(ZKAnimations.spring))
                        .labelsHidden()
                        .toggleStyle(ZKToggleStyle())
                }

                if viewModel.preferences.restoreOnEscape {
                    Divider()
                        .padding(.top, 4)

                    // Key Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chọn phím khôi phục")
                            .font(ZKTypography.caption.bold())
                            .foregroundColor(ZKColors.textPrimary)

                        HStack(spacing: 12) {
                            ZKRestoreKeyButton(
                                symbol: "⎋",
                                name: "ESC",
                                restoreKey: .esc,
                                selectedKey: $viewModel.preferences.restoreKey
                            )
                            ZKRestoreKeyButton(
                                symbol: "⌥",
                                name: "Option",
                                restoreKey: .option,
                                selectedKey: $viewModel.preferences.restoreKey
                            )
                            ZKRestoreKeyButton(
                                symbol: "⌃",
                                name: "Control",
                                restoreKey: .control,
                                selectedKey: $viewModel.preferences.restoreKey
                            )
                        }

                        Text("Mặc định: ESC (⎋). Ví dụ: \"việt\" → ⎋ → \"vieejt\"")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textTertiary)
                    }
                    .transition(.opacity)

                    // Comprehensive conflict warning
                    if !conflictingSections.isEmpty {
                        ZKConflictWarningView(message: "Phím đang trùng với: \(conflictingSections.joined(separator: ", "))")
                    }
                }
            }
            .animation(ZKAnimations.spring, value: viewModel.preferences.restoreOnEscape)
            .onChange(of: viewModel.preferences.restoreOnEscape) { _ in
                viewModel.userDidInteractWithHotkeySection()
            }
            .onChange(of: viewModel.preferences.restoreKey) { _ in
                viewModel.userDidInteractWithHotkeySection()
            }
        }
    }
}

// MARK: - Conflict Warning View (Reusable)

struct ZKConflictWarningView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 14))

            Text(message)
                .font(ZKTypography.caption)
                .foregroundColor(.orange)

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Temp Off Spelling Key Button (Radio Style)

/// A styled radio button for temp off spelling key selection
struct ZKTempOffSpellingKeyButton: View {
    let symbol: String
    let name: String
    let keyCode: UInt16
    @Binding var selectedKeyCode: UInt16
    
    @State private var isHovered = false

    private var isSelected: Bool {
        selectedKeyCode == keyCode
    }

    var body: some View {
        Button(action: {
            withAnimation(ZKAnimations.spring) {
                selectedKeyCode = keyCode
            }
        }) {
            VStack(spacing: 6) {
                Text(symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .white : ZKColors.textPrimary)

                Text(name)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : ZKColors.textSecondary)
            }
            .frame(width: 70, height: 56)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ZKColors.accentGradient)
                        .shadow(color: ZKColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ZKColors.glassBackground)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : ZKColors.glassBorder, lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : (isSelected ? 1.0 : 0.98))
        }
        .buttonStyle(.plain)
        .animation(ZKAnimations.spring, value: isSelected)
        .animation(ZKAnimations.springFast, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Temp Off Spelling Configuration Section

struct ZKTempOffSpellingConfigSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel

    // Get list of conflicting sections for display
    private var conflictingSections: [String] {
        guard viewModel.preferences.tempOffSpellingEnabled else { return [] }
        var conflicts: [String] = []
        
        // Check conflict with restore key
        if viewModel.preferences.restoreOnEscape && 
           viewModel.preferences.tempOffSpellingKey == viewModel.preferences.restoreKey.rawValue {
            conflicts.append("Phím khôi phục nguyên gốc")
        }
        
        // Check conflict with pause key (Tạm tắt gõ tiếng Việt)
        if viewModel.preferences.pauseKeyEnabled && 
           viewModel.preferences.tempOffSpellingKey == viewModel.preferences.pauseKey {
            conflicts.append("Phím tạm tắt gõ tiếng Việt")
        }
        
        return conflicts
    }

    var body: some View {
        ZKSection("Phím tạm tắt kiểm tra chính tả") {
            VStack(alignment: .leading, spacing: 16) {
                // Enable toggle with icon
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ZKColors.accent.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: "textformat.abc.dottedunderline")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ZKColors.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bật tính năng tạm tắt chính tả")
                            .font(ZKTypography.body)
                            .foregroundColor(ZKColors.textPrimary)

                        Text("Giữ phím để tạm thời tắt kiểm tra chính tả")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.preferences.tempOffSpellingEnabled.animation(ZKAnimations.spring))
                        .labelsHidden()
                        .toggleStyle(ZKToggleStyle())
                }

                if viewModel.preferences.tempOffSpellingEnabled {
                    Divider()
                        .padding(.top, 4)

                    // Key Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chọn phím tạm tắt chính tả")
                            .font(ZKTypography.caption.bold())
                            .foregroundColor(ZKColors.textPrimary)

                        HStack(spacing: 12) {
                            ZKTempOffSpellingKeyButton(
                                symbol: "⌃",
                                name: "Control",
                                keyCode: 59,
                                selectedKeyCode: $viewModel.preferences.tempOffSpellingKey
                            )
                            ZKTempOffSpellingKeyButton(
                                symbol: "⌥",
                                name: "Option",
                                keyCode: 58,
                                selectedKeyCode: $viewModel.preferences.tempOffSpellingKey
                            )
                        }

                        Text("Mặc định: Option (⌥). Ví dụ: giữ ⌥ gõ \"tooi\" → không chuyển thành \"tôi\"")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textTertiary)
                    }
                    .transition(.opacity)

                    // Comprehensive conflict warning
                    if !conflictingSections.isEmpty {
                        ZKConflictWarningView(message: "Phím đang trùng với: \(conflictingSections.joined(separator: ", "))")
                    }
                }
            }
            .animation(ZKAnimations.spring, value: viewModel.preferences.tempOffSpellingEnabled)
            .onChange(of: viewModel.preferences.tempOffSpellingEnabled) { _ in
                viewModel.userDidInteractWithHotkeySection()
            }
            .onChange(of: viewModel.preferences.tempOffSpellingKey) { _ in
                viewModel.userDidInteractWithHotkeySection()
            }
        }
    }
}

