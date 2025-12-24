//
//  ZKToggleRow.swift
//  ZendyKey
//
//  Reusable row component with icon, title, subtitle, and optional description
//  Used for: Settings rows with consistent styling
//

import SwiftUI

// MARK: - ZKToggleRow

/// A row component with icon, title, optional subtitle, and optional description
struct ZKToggleRow<TrailingContent: View>: View {
    let icon: String
    var iconText: String? = nil  // For custom text icon like "VI"
    var iconBackground: AnyShapeStyle? = nil
    let title: String
    var subtitle: String? = nil
    var description: String? = nil
    var trailingContent: TrailingContent
    
    @State private var isHovered = false
    
    // Initializer with trailing content
    init(
        icon: String,
        iconText: String? = nil,
        iconBackground: AnyShapeStyle? = nil,
        title: String,
        subtitle: String? = nil,
        description: String? = nil,
        @ViewBuilder trailing: () -> TrailingContent
    ) {
        self.icon = icon
        self.iconText = iconText
        self.iconBackground = iconBackground
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.trailingContent = trailing()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            iconView
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                // Subtitle
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Description
                if let description = description {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.8))
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Trailing content
            trailingContent
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    // MARK: - Icon View
    
    @ViewBuilder
    private var iconView: some View {
        let iconSize: CGFloat = 36
        let cornerRadius: CGFloat = 10
        
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(iconBackground ?? AnyShapeStyle(ZKColors.accent.opacity(0.12)))
                .frame(width: iconSize, height: iconSize)
            
            // Icon or Text
            if let iconText = iconText {
                Text(iconText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(ZKColors.accentGradient)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ZKColors.accentGradient)
            }
        }
    }
}

// MARK: - ZKToggleRow without trailing content

extension ZKToggleRow where TrailingContent == EmptyView {
    init(
        icon: String,
        iconText: String? = nil,
        iconBackground: AnyShapeStyle? = nil,
        title: String,
        subtitle: String? = nil,
        description: String? = nil
    ) {
        self.icon = icon
        self.iconText = iconText
        self.iconBackground = iconBackground
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.trailingContent = EmptyView()
    }
}

// MARK: - ZKToggleRowToggle (Row with toggle switch)

struct ZKToggleRowToggle: View {
    let icon: String
    var iconText: String? = nil
    var iconBackground: AnyShapeStyle? = nil
    let title: String
    var subtitle: String? = nil
    var description: String? = nil
    @Binding var isOn: Bool
    
    var body: some View {
        ZKToggleRow(
            icon: icon,
            iconText: iconText,
            iconBackground: iconBackground,
            title: title,
            subtitle: subtitle,
            description: description
        ) {
            Toggle("", isOn: $isOn)
                .toggleStyle(ZKToggleStyle())
                .labelsHidden()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ZKToggleRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Row with text icon
            ZKToggleRow(
                icon: "character",
                iconText: "VI",
                title: "Gõ tiếng Việt",
                subtitle: "Đang gõ tiếng Việt 🇻🇳"
            )
            
            Divider()
            
            // Row with SF Symbol icon
            ZKToggleRow(
                icon: "speaker.wave.2.fill",
                title: "Phát âm thanh khi chuyển chế độ",
                subtitle: "Phát beep khi bấm phím tắt"
            ) {
                Toggle("", isOn: .constant(true))
                    .toggleStyle(ZKToggleStyle())
                    .labelsHidden()
            }
            
            Divider()
            
            // Row with description
            ZKToggleRow(
                icon: "arrow.uturn.backward",
                title: "Hoàn tác gõ tiếng Việt bằng phím Esc",
                subtitle: "Nhấn Esc ngay sau khi gõ để hoàn tác việc bỏ dấu",
                description: "Ví dụ: \"tiếng\" → \"tieesng\""
            )
            
            Divider()
            
            // Row with toggle
            ZKToggleRow(
                icon: "globe",
                title: "Bật/tắt gõ tiếng Việt",
                subtitle: "Mặc định: ⌘⇧V"
            ) {
                Toggle("", isOn: .constant(true))
                    .toggleStyle(ZKToggleStyle())
                    .labelsHidden()
            }
        }
        .padding(20)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
#endif
