//
//  ZKGradientButton.swift
//  ZendyKey
//
//  Reusable gradient button component with icon and text
//

import SwiftUI

// MARK: - ZKGradientButton

/// A button with gradient background, optional icon, and text
struct ZKGradientButton: View {
    let title: String
    var icon: String? = nil
    var gradient: LinearGradient = ZKColors.accentGradient
    var cornerRadius: CGFloat = 8
    var paddingHorizontal: CGFloat = 14
    var paddingVertical: CGFloat = 8
    var iconSize: CGFloat = 12
    var fontStyle: Font = ZKTypography.caption
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .medium))
                }
                Text(title)
                    .font(fontStyle)
            }
            .foregroundColor(.white)
            .padding(.horizontal, paddingHorizontal)
            .padding(.vertical, paddingVertical)
            .background(gradient)
            .cornerRadius(cornerRadius)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Convenience Initializers

extension ZKGradientButton {
    /// Primary gradient button (default purple gradient)
    static func primary(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ZKGradientButton {
        ZKGradientButton(
            title: title,
            icon: icon,
            gradient: ZKColors.accentGradient,
            action: action
        )
    }
    
    /// Success gradient button (green gradient)
    static func success(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ZKGradientButton {
        ZKGradientButton(
            title: title,
            icon: icon,
            gradient: ZKColors.successGradient,
            action: action
        )
    }
    
    /// Warning gradient button (orange gradient)
    static func warning(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ZKGradientButton {
        ZKGradientButton(
            title: title,
            icon: icon,
            gradient: ZKColors.warningGradient,
            action: action
        )
    }
    
    /// Danger gradient button (red gradient)
    static func danger(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> ZKGradientButton {
        ZKGradientButton(
            title: title,
            icon: icon,
            gradient: ZKColors.dangerGradient,
            action: action
        )
    }
}

// MARK: - Preview

#if DEBUG
struct ZKGradientButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ZKGradientButton.primary(title: "Thêm ứng dụng", icon: "plus.app") {}
            ZKGradientButton.success(title: "Mở Cài đặt", icon: "gearshape") {}
            ZKGradientButton.warning(title: "Cảnh báo", icon: "exclamationmark.triangle") {}
            ZKGradientButton.danger(title: "Xóa tất cả", icon: "trash") {}
            
            // Custom gradient
            ZKGradientButton(
                title: "Custom Button",
                icon: "star.fill",
                gradient: LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing),
                action: {}
            )
        }
        .padding(40)
        .background(Color(hex: "1a1a2e"))
    }
}
#endif
