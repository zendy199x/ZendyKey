//
//  ZKRadioGroup.swift
//  ZendyKey
//
//  Reusable radio button group with gradient selection
//  Used for: Code Table picker (Unicode, TCVN3, VNI Windows, etc.)
//

import SwiftUI

// MARK: - ZKRadioGroup

struct ZKRadioGroup<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let titleForOption: (T) -> String
    var columns: Int = 2
    
    @Namespace private var radioAnimation
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(options, id: \.self) { option in
                radioButton(for: option)
            }
        }
    }
    
    @ViewBuilder
    private func radioButton(for option: T) -> some View {
        let isSelected = selection == option
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = option
            }
        } label: {
            HStack(spacing: 12) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(titleForOption(option))
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                if isSelected {
                    ZKColors.accentGradient
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .matchedGeometryEffect(id: "radioSelection", in: radioAnimation)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.03))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Convenience Initializer for CodeTable

extension ZKRadioGroup where T == CodeTable {
    init(selection: Binding<CodeTable>, columns: Int = 2) {
        self._selection = selection
        self.options = CodeTable.allCases
        self.titleForOption = { $0.displayName }
        self.columns = columns
    }
}

// MARK: - Preview

#Preview("ZKRadioGroup") {
    VStack(spacing: 20) {
        ZKRadioGroup(
            selection: .constant(CodeTable.unicode),
            options: CodeTable.allCases,
            titleForOption: { $0.displayName },
            columns: 2
        )
        
        // Using convenience initializer
        ZKRadioGroup(selection: .constant(.tcvn3))
    }
    .padding(40)
    .background(Color(hex: "1a1a2e"))
}
