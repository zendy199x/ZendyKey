//
//  ZKActionButton.swift
//  ZendyKey
//
//  Reusable action button component for large buttons
//  Used for: "Hoàn tất", "Tiếp tục", "Quay lại", etc.
//

import SwiftUI

// MARK: - Button Style Enum

enum ZKActionButtonStyle {
    case primary      // Gradient background (accent)
    case secondary    // Transparent with light background
    case success      // Green gradient
    case danger       // Red gradient
    case ghost        // Transparent with border
    
    var background: some View {
        switch self {
        case .primary:
            AnyView(ZKColors.accentGradient)
        case .secondary:
            AnyView(Color.white.opacity(0.1))
        case .success:
            AnyView(ZKColors.successGradient)
        case .danger:
            AnyView(ZKColors.dangerGradient)
        case .ghost:
            AnyView(Color.clear)
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary, .success, .danger:
            return .white
        case .secondary, .ghost:
            return .white.opacity(0.7)
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .primary:
            return ZKColors.accent.opacity(0.4)
        case .success:
            return Color(hex: "38EF7D").opacity(0.4)
        case .danger:
            return Color.red.opacity(0.4)
        case .secondary, .ghost:
            return .clear
        }
    }
    
    var borderColor: Color {
        switch self {
        case .ghost:
            return Color.white.opacity(0.2)
        default:
            return .clear
        }
    }
}

// MARK: - ZKActionButton

struct ZKActionButton: View {
    let title: String
    var icon: String? = nil
    var iconPosition: IconPosition = .trailing
    var style: ZKActionButtonStyle = .primary
    var isDisabled: Bool = false
    var action: () -> Void
    
    enum IconPosition {
        case leading
        case trailing
    }
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon, iconPosition == .leading {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                
                if let icon = icon, iconPosition == .trailing {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundColor(style.foregroundColor.opacity(isDisabled ? 0.5 : 1))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Group {
                    if style == .ghost {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(style.borderColor, lineWidth: 1)
                            .background(
                                Color.white.opacity(isHovered ? 0.08 : 0)
                                    .clipShape(Capsule())
                            )
                    } else {
                        style.background
                            .opacity(isDisabled ? 0.5 : (isPressed ? 0.8 : (isHovered ? 0.9 : 1)))
                    }
                }
            )
            .clipShape(Capsule())
            .shadow(color: style.shadowColor, radius: isHovered ? 12 : 8, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
        }
        .buttonStyle(.plain)
        .focusable(false)
        .disabled(isDisabled)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview("ZKActionButton Styles") {
    VStack(spacing: 20) {
        // Primary (Tiếp tục)
        ZKActionButton(
            title: "Tiếp tục",
            icon: "arrow.right",
            style: .primary
        ) {
            print("Primary tapped")
        }
        
        // Secondary (Quay lại)
        ZKActionButton(
            title: "Quay lại",
            icon: "arrow.left",
            iconPosition: .leading,
            style: .secondary
        ) {
            print("Secondary tapped")
        }
        
        // Success (Hoàn tất)
        ZKActionButton(
            title: "Hoàn tất",
            icon: "checkmark",
            style: .success
        ) {
            print("Success tapped")
        }
        
        // Danger
        ZKActionButton(
            title: "Xóa",
            icon: "trash",
            iconPosition: .leading,
            style: .danger
        ) {
            print("Danger tapped")
        }
        
        // Ghost
        ZKActionButton(
            title: "Hủy",
            style: .ghost
        ) {
            print("Ghost tapped")
        }
        
        // Disabled
        ZKActionButton(
            title: "Đã vô hiệu",
            style: .primary,
            isDisabled: true
        ) {
            print("Disabled tapped")
        }
    }
    .padding(40)
    .background(Color(hex: "1a1a2e"))
}
