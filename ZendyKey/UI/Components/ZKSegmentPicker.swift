//
//  ZKSegmentPicker.swift
//  ZendyKey
//
//  Reusable horizontal segment picker with gradient selection and sliding animation
//  Used for: Input Method picker and other segmented selections
//

import SwiftUI

// MARK: - ZKSegmentPicker

struct ZKSegmentPicker<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let titleForOption: (T) -> String
    var descriptionForOption: ((T) -> String)? = nil
    var showDividers: Bool = true
    
    @Namespace private var animation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Segment buttons
            HStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                    ZKSegmentButton(
                        title: titleForOption(option),
                        isSelected: selection == option,
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
                            .padding(.vertical, 6)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(ZKColors.glassBackground.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
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

// MARK: - ZKSegmentButton

private struct ZKSegmentButton: View {
    let title: String
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            // ZStack with hidden semibold text to reserve width and prevent layout shift
            ZStack {
                // Hidden semibold text to reserve maximum width
                Text(title)
                    .font(ZKTypography.body.weight(.semibold))
                    .opacity(0)
                
                // Visible text with actual styling
                Text(title)
                    .font(ZKTypography.body.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (isHovered ? ZKColors.textPrimary : ZKColors.textSecondary))
            }
            .frame(minWidth: 80)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    ZKColors.accentGradient
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .matchedGeometryEffect(id: "SelectedIndicator", in: namespace)
                } else if isHovered {
                    Color.white.opacity(0.08)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
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
        self.descriptionForOption = showDescription ? { $0.description } : nil
        self.showDividers = showDividers
    }
}

// MARK: - Preview

#Preview("ZKSegmentPicker") {
    VStack(spacing: 20) {
        // InputMethod picker with description
        ZKSegmentPicker(selection: .constant(.telex))
        
        // InputMethod picker without description
        ZKSegmentPicker(selection: .constant(.vni), showDescription: false)
        
        // Custom options with description
        ZKSegmentPicker(
            selection: .constant(InputMethod.viqr),
            options: InputMethod.orderedCases,
            titleForOption: { $0.displayName },
            descriptionForOption: { $0.description }
        )
    }
    .padding(40)
    .background(Color(hex: "1a1a2e"))
}
