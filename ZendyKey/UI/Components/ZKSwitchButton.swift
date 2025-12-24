//
//  ZKSwitchButton.swift
//  ZendyKey
//
//  Convenience view for custom gradient switch using ZKToggleStyle
//

import SwiftUI

// MARK: - ZKSwitchButton

/// Convenience view that wraps a Toggle with ZKToggleStyle
/// Uses the gradient switch style defined in ZKDesignSystem
struct ZKSwitchButton: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(ZKToggleStyle())
            .labelsHidden()
    }
}

// MARK: - Preview

#Preview("ZKSwitchButton") {
    VStack(spacing: 30) {
        // On state
        ZKSwitchButton(isOn: .constant(true))
        
        // Off state
        ZKSwitchButton(isOn: .constant(false))
        
        // With Toggle syntax
        Toggle("Enable feature", isOn: .constant(true))
            .toggleStyle(ZKToggleStyle())
    }
    .padding(40)
    .background(Color(hex: "1a1a2e"))
}
