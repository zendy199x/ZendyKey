//
//  ZKGridPicker.swift
//  ZendyKey
//
//  Generic grid layout picker with radio buttons and sliding animation
//  Used for: Code Table, or any grid-based selection
//

import SwiftUI

// MARK: - ZKGridPicker

struct ZKGridPicker<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let titleForOption: (T) -> String
    var columnCount: Int = 2
    
    @Namespace private var animation
    
    // Grid layout with configurable columns
    private var columns: [GridItem] {
        let count = max(1, columnCount)
        return Array(repeating: GridItem(.flexible()), count: count)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(options, id: \.self) { option in
                ZKGridButton(
                    title: titleForOption(option),
                    isSelected: selection == option,
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selection = option
                    }
                }
            }
        }
    }
}

// MARK: - ZKGridButton

private struct ZKGridButton: View {
    let title: String
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Selection indicator circle (radio button style)
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : ZKColors.textTertiary.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    
                    if isSelected {
                        Circle()
                            .fill(ZKColors.accentGradient)
                            .frame(width: 18, height: 18)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                Text(title)
                    .font(ZKTypography.body.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (isHovered ? ZKColors.textPrimary : ZKColors.textSecondary))
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    ZKColors.accentGradient
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .matchedGeometryEffect(id: "GridSelectedIndicator", in: namespace)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.08))
                }
            }
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Convenience Initializer for CodeTable

extension ZKGridPicker where T == CodeTable {
    init(selection: Binding<CodeTable>, columnCount: Int = 2) {
        self._selection = selection
        self.options = CodeTable.allCases
        self.titleForOption = { $0.displayName }
        self.columnCount = columnCount
    }
}

// MARK: - Preview

#Preview("ZKGridPicker") {
    VStack(spacing: 20) {
        // CodeTable with default 2 columns
        ZKGridPicker(selection: .constant(CodeTable.unicode))
        
        // CodeTable with 3 columns
        ZKGridPicker(selection: .constant(CodeTable.vniWindows), columnCount: 3)
        
        // CodeTable with 1 column (vertical list)
        ZKGridPicker(selection: .constant(CodeTable.tcvn3), columnCount: 1)
    }
    .padding(40)
    .background(Color(hex: "1a1a2e"))
}
