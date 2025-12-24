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

// MARK: - Pause Key Configuration Section

struct ZKPauseKeyConfigSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel

    // Check for conflict with restore key
    private var hasPauseRestoreConflict: Bool {
        guard viewModel.preferences.pauseKeyEnabled && viewModel.preferences.restoreOnEscape else { return false }
        return viewModel.preferences.pauseKey == viewModel.preferences.restoreKey.rawValue
    }

    var body: some View {
        ZKSection( "Tạm dừng gõ tiếng Việt") {
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
                        Text("Bật tính năng tạm dừng")
                            .font(ZKTypography.body)
                            .foregroundColor(ZKColors.textPrimary)

                        Text("Nhấn giữ phím để tạm thời chuyển sang tiếng Anh")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.preferences.pauseKeyEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if viewModel.preferences.pauseKeyEnabled {
                    Divider()

                    // Key Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chọn phím tạm dừng")
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

                        Text("Mặc định: Option (⌥)")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textTertiary)
                    }

                    // Conflict warning
                    if hasPauseRestoreConflict {
                        ZKConflictWarningView(message: "Phím tạm dừng trùng với phím khôi phục")
                    }
                }
            }
        }
    }
}

// MARK: - Restore Key Configuration Section

struct ZKRestoreKeyConfigSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel

    var body: some View {
        ZKSection( "Khôi phục nguyên gốc") {
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

                    Toggle("", isOn: $viewModel.preferences.restoreOnEscape)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if viewModel.preferences.restoreOnEscape {
                    Divider()

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

                        Text("Mặc định: ESC (⎋)")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textTertiary)
                    }
                }
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
