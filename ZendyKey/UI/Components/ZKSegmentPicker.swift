//
//  ZKSegmentPicker.swift
//  ZendyKey
//
//  Reusable horizontal segment picker with gradient selection and sliding animation
//  Used for: Input Method picker, Theme picker and other segmented selections
//

import SwiftUI

// MARK: - ZKSegmentPicker

struct ZKSegmentPicker<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let titleForOption: (T) -> String
    var iconForOption: ((T) -> String)? = nil
    var descriptionForOption: ((T) -> String)? = nil
    var showDividers: Bool = true
    var style: ZKSegmentPickerStyle = .compact
    
    @Namespace private var animation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Segment buttons
            HStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                    ZKSegmentButton(
                        title: titleForOption(option),
                        icon: iconForOption?(option),
                        isSelected: selection == option,
                        style: style,
                        namespace: animation
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selection = option
                        }
                    }
                    
                    // Add vertical divider between buttons (not at the end)
                    if showDividers && index < options.count - 1 {
                        Rectangle()
                            .fill(ZKColors.glassBorder)
                            .frame(width: 1)
                            .padding(.vertical, style == .large ? 12 : 6)
                    }
                }
            }
            .padding(style == .large ? 6 : 4)  // Inner padding like PHTV design
            .background(
                RoundedRectangle(cornerRadius: style == .large ? 14 : 10)
                    .fill(ZKColors.glassBackground.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: style == .large ? 14 : 10)
                    .stroke(ZKColors.glassBorder, lineWidth: 1)
            )
            
            // Optional description
            if let descriptionForOption = descriptionForOption {
                Text(descriptionForOption(selection))
                    .font(ZKTypography.caption)
                    .foregroundColor(ZKColors.textTertiary)
                    .animation(.easeInOut(duration: 0.2), value: selection)
            }
        }
    }
}

// MARK: - Style

enum ZKSegmentPickerStyle {
    case compact   // For input method picker (text only, small)
    case large     // For theme picker (icon + text, PHTV style)
}

// MARK: - ZKSegmentButton

private struct ZKSegmentButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let style: ZKSegmentPickerStyle
    var namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: style == .large ? 6 : 2) {
                // Icon (for large style)
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: style == .large ? 22 : 16, weight: .medium))
                        .foregroundColor(isSelected ? .white : ZKColors.textSecondary)
                }
                
                // ZStack with hidden semibold text to reserve width and prevent layout shift
                ZStack {
                    // Hidden semibold text to reserve maximum width
                    Text(title)
                        .font(style == .large ? ZKTypography.body.weight(.semibold) : ZKTypography.caption.weight(.semibold))
                        .opacity(0)
                    
                    // Visible text with actual styling
                    Text(title)
                        .font(style == .large ? ZKTypography.body.weight(isSelected ? .semibold : .regular) : ZKTypography.caption.weight(isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : (isHovered ? ZKColors.textPrimary : ZKColors.textSecondary))
                }
            }
            .frame(minWidth: style == .large ? 90 : 70)
            .padding(.horizontal, style == .large ? 16 : 12)
            .padding(.vertical, style == .large ? 12 : 8)
            .background {
                if isSelected {
                    ZKColors.accentGradient
                        .clipShape(RoundedRectangle(cornerRadius: style == .large ? 10 : 6))
                        .matchedGeometryEffect(id: "SelectedIndicator", in: namespace)
                        .shadow(color: ZKColors.accent.opacity(0.3), radius: 8, x: 0, y: 2)
                } else if isHovered {
                    Color.white.opacity(0.08)
                        .clipShape(RoundedRectangle(cornerRadius: style == .large ? 10 : 6))
                }
            }
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Convenience Initializer for InputMethod

extension ZKSegmentPicker where T == InputMethod {
    init(selection: Binding<InputMethod>, showDescription: Bool = true, showDividers: Bool = true) {
        self._selection = selection
        self.options = InputMethod.orderedCases
        self.titleForOption = { $0.displayName }
        self.iconForOption = nil
        self.descriptionForOption = showDescription ? { $0.description } : nil
        self.showDividers = showDividers
        self.style = .compact
    }
}

// MARK: - Convenience Initializer for AppearanceMode (Theme Picker)

extension ZKSegmentPicker where T == Int {
    /// Create a theme/appearance picker with icon + text (PHTV style)
    /// Values: 0 = system/auto, 1 = dark, 2 = light
    static func themePicker(selection: Binding<Int>) -> some View {
        ZKSegmentPicker(
            selection: selection,
            options: [0, 1, 2],
            titleForOption: { mode in
                switch mode {
                case 0: return "Tự động"
                case 1: return "Tối"
                case 2: return "Sáng"
                default: return ""
                }
            },
            iconForOption: { mode in
                switch mode {
                case 0: return "circle.lefthalf.filled"
                case 1: return "moon.fill"
                case 2: return "sun.max.fill"
                default: return "circle"
                }
            },
            descriptionForOption: { _ in
                "Chọn chế độ sáng, tối hoặc tự động theo hệ thống"
            },
            showDividers: true,
            style: .large
        )
    }
}

// MARK: - Preview

#Preview("ZKSegmentPicker") {
    VStack(spacing: 30) {
        // Theme picker (PHTV style with icons)
        ZKSegmentPicker<Int>.themePicker(selection: .constant(0))
        
        // InputMethod picker with description
        ZKSegmentPicker(selection: .constant(.telex))
        
        // InputMethod picker without description
        ZKSegmentPicker(selection: .constant(.vni), showDescription: false)
    }
    .padding(40)
    .background(Color(hex: "1a1a2e"))
}
