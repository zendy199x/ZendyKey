//
//  ZKInputMethodStep.swift
//  ZendyKey
//
//  Input method selection step for onboarding flow
//

import SwiftUI

// MARK: - Input Method Step View

struct ZKInputMethodStep: View {
    @Binding var selectedInputMethod: InputMethod
    let accentColor: Color
    var namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Logo
            if let logo = NSImage(named: "ZendyKeyLogo") {
                Image(nsImage: logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            VStack(spacing: 8) {
                Text("Chọn kiểu gõ")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Bạn có thể thay đổi sau trong Cài đặt")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Input method options with smooth animation
            VStack(spacing: 12) {
                InputMethodOptionCard(
                    title: "Telex",
                    description: "aa → â, aw → ă, s → sắc",
                    example: "Việt Nam → Vieetj Nam",
                    isSelected: selectedInputMethod == .telex,
                    accentColor: accentColor,
                    namespace: namespace
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedInputMethod = .telex
                    }
                }
                
                InputMethodOptionCard(
                    title: "VNI",
                    description: "a6 → â, a8 → ă, 1 → sắc",
                    example: "Việt Nam → Vie6t1 Nam",
                    isSelected: selectedInputMethod == .vni,
                    accentColor: accentColor,
                    namespace: namespace
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedInputMethod = .vni
                    }
                }
                
                InputMethodOptionCard(
                    title: "VIQR",
                    description: "a^ → â, a( → ă, ' → sắc",
                    example: "Việt Nam → Vie^.t Nam",
                    isSelected: selectedInputMethod == .viqr,
                    accentColor: accentColor,
                    namespace: namespace
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedInputMethod = .viqr
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Input Method Option Card Component

struct InputMethodOptionCard: View {
    let title: String
    let description: String
    let example: String
    let isSelected: Bool
    let accentColor: Color
    var namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(example)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(accentColor.opacity(0.8))
                        .padding(.top, 2)
                }
                
                Spacer()
                
                // Animated checkmark
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .opacity(isSelected ? 0 : 1)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(accentColor)
                            .matchedGeometryEffect(id: "selectedCheck", in: namespace)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
