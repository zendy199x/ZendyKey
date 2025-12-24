//
//  ZKSegmentPicker.swift
//  ZendyKey
//
//  Reusable horizontal segment picker with gradient selection
//  Used for: Input Method picker (Telex, VNI, VIQR, etc.)
//

import SwiftUI

// MARK: - ZKSegmentPicker

struct ZKSegmentPicker<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let titleForOption: (T) -> String
    var descriptionForOption: ((T) -> String)? = nil
    
    @Namespace private var segmentAnimation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Segment buttons
            HStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    segmentButton(for: option)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Optional description
            if let descriptionForOption = descriptionForOption {
                Text(descriptionForOption(selection))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .animation(.easeInOut(duration: 0.2), value: selection)
            }
        }
    }
    
    @ViewBuilder
    private func segmentButton(for option: T) -> some View {
        let isSelected = selection == option
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = option
            }
        } label: {
            Text(titleForOption(option))
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        ZKColors.accentGradient
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .matchedGeometryEffect(id: "segmentSelection", in: segmentAnimation)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Convenience Initializer for InputMethod

extension ZKSegmentPicker where T == InputMethod {
    init(selection: Binding<InputMethod>, showDescription: Bool = true) {
        self._selection = selection
        self.options = InputMethod.orderedCases
        self.titleForOption = { $0.displayName }
        self.descriptionForOption = showDescription ? { $0.description } : nil
    }
}

// MARK: - Preview

#Preview("ZKSegmentPicker") {
    VStack(spacing: 20) {
        // With description
        ZKSegmentPicker(selection: .constant(.telex))
        
        // Without description
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

