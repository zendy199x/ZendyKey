//
//  ZKMenuBarHeaderView.swift
//  ZendyKey
//
//  Premium menu bar header with glassmorphism, gradient toggle, and micro-interactions
//

import SwiftUI

/// Premium menu bar header view
struct ZKMenuBarHeaderView: View {
    @Binding var isVietnameseEnabled: Bool
    let inputMethodName: String
    let hotkeyDisplay: String
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Logo with glow effect
            logoSection
            
            // App info
            infoSection
            
            Spacer()
            
            // Premium gradient toggle
            gradientToggle
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 260, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .opacity(isHovered ? 0.8 : 0.5)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        ZStack {
            // Subtle glow
            if isVietnameseEnabled {
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .blur(radius: 8)
            }
            
            // Logo
            if let logo = NSImage(named: "ZendyKeyLogo") {
                Image(nsImage: logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: isVietnameseEnabled ? Color.purple.opacity(0.4) : Color.clear, radius: 6)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("ZK")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(ZKAnimations.spring, value: isPressed)
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            // App name with flag
            HStack(spacing: 6) {
                Text("ZendyKey")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(isVietnameseEnabled ? "🇻🇳" : "🇬🇧")
                    .font(.system(size: 12))
            }
            
            // Status text
            HStack(spacing: 4) {
                if isVietnameseEnabled {
                    Text(inputMethodName)
                        .foregroundColor(.secondary)
                } else {
                    Text("Đã tắt")
                        .foregroundColor(.secondary)
                }
                
                Text("·")
                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
                
                Text(hotkeyDisplay)
                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
            }
            .font(.system(size: 11, weight: .medium))
        }
    }
    
    // MARK: - Gradient Toggle
    
    private var gradientToggle: some View {
        ZStack {
            // Track
            Capsule()
                .fill(isVietnameseEnabled ? gradientPurple : LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: 48, height: 28)
                .shadow(color: isVietnameseEnabled ? Color.purple.opacity(0.4) : Color.clear, radius: 4, x: 0, y: 2)
            
            // Thumb
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                .frame(width: 24, height: 24)
                .offset(x: isVietnameseEnabled ? 10 : -10)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(ZKAnimations.spring, value: isVietnameseEnabled)
        .animation(ZKAnimations.spring, value: isPressed)
        .onTapGesture {
            // Press feedback
            withAnimation(.easeIn(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.15)) {
                    isPressed = false
                }
            }
            
            isVietnameseEnabled.toggle()
        }
    }
    
    // MARK: - Gradients
    
    private var gradientPurple: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.35, blue: 0.85),
                Color(red: 0.55, green: 0.45, blue: 0.95)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Preview

#if DEBUG
struct ZKMenuBarHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ZKMenuBarHeaderView(
                isVietnameseEnabled: .constant(true),
                inputMethodName: "Telex",
                hotkeyDisplay: "⇧⌘V"
            )
            
            ZKMenuBarHeaderView(
                isVietnameseEnabled: .constant(false),
                inputMethodName: "Telex",
                hotkeyDisplay: "⇧⌘V"
            )
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}
#endif
