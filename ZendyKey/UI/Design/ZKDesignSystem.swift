//
//  ZKDesignSystem.swift
//  ZendyKey
//
//  Modern Design System with Glassmorphism, Animations, and Premium Styling
//

import SwiftUI

// MARK: - Color Palette

struct ZKColors {
    // Primary accent gradient
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradientReverse = LinearGradient(
        colors: [Color(hex: "764BA2"), Color(hex: "667EEA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Secondary gradients
    static let successGradient = LinearGradient(
        colors: [Color(hex: "11998E"), Color(hex: "38EF7D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [Color(hex: "F2994A"), Color(hex: "F2C94C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Glass backgrounds
    static let glassBackground = Color.white.opacity(0.05)
    static let glassBorder = Color.white.opacity(0.1)
    static let glassHighlight = Color.white.opacity(0.15)
    
    // Text hierarchy
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    
    // Accent colors
    static let accent = Color(hex: "667EEA")
    static let accentLight = Color(hex: "8B9FFF")
    
    // Status colors
    static let success = Color(hex: "38EF7D")
    static let warning = Color(hex: "F2994A")
    static let error = Color(hex: "EB5757")
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Animation Presets

struct ZKAnimations {
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let springFast = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let easeOut = Animation.easeOut(duration: 0.2)
    static let easeInOut = Animation.easeInOut(duration: 0.25)
}

// MARK: - Typography

struct ZKTypography {
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title2 = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 14, weight: .regular, design: .default)
    static let callout = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - Glass Card View

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    
    init(padding: CGFloat = 16, cornerRadius: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(ZKColors.glassBorder, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Glass Background Modifier

struct GlassBackgroundModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    var showBorder: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(showBorder ? ZKColors.glassBorder : .clear, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = 12, showBorder: Bool = true) -> some View {
        modifier(GlassBackgroundModifier(cornerRadius: cornerRadius, showBorder: showBorder))
    }
}

// MARK: - Animated Button Style

struct ZKButtonStyle: ButtonStyle {
    var style: ButtonStyleType = .primary
    
    enum ButtonStyleType {
        case primary, secondary, ghost
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ZKTypography.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(backgroundForStyle(isPressed: configuration.isPressed))
            .foregroundColor(foregroundForStyle)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderForStyle, lineWidth: style == .ghost ? 1 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(ZKAnimations.springFast, value: configuration.isPressed)
    }
    
    @ViewBuilder
    private func backgroundForStyle(isPressed: Bool) -> some View {
        switch style {
        case .primary:
            ZKColors.accentGradient
                .opacity(isPressed ? 0.8 : 1.0)
        case .secondary:
            Color.white.opacity(isPressed ? 0.15 : 0.1)
        case .ghost:
            Color.clear
        }
    }
    
    private var foregroundForStyle: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .ghost:
            return ZKColors.textPrimary
        }
    }
    
    private var borderForStyle: Color {
        switch style {
        case .ghost:
            return ZKColors.glassBorder
        default:
            return .clear
        }
    }
}

// MARK: - Hover Effect Modifier

struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    var scaleAmount: CGFloat = 1.02
    var showBackground: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background(
                showBackground ?
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
                : nil
            )
            .scaleEffect(isHovered ? scaleAmount : 1.0)
            .animation(ZKAnimations.easeOut, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func hoverEffect(scale: CGFloat = 1.02, showBackground: Bool = true) -> some View {
        modifier(HoverEffectModifier(scaleAmount: scale, showBackground: showBackground))
    }
}

// MARK: - Animated Toggle Style

struct ZKToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(ZKTypography.body)
            
            Spacer()
            
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? ZKColors.accentGradient : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 44, height: 26)
                
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .frame(width: 22, height: 22)
                    .offset(x: configuration.isOn ? 9 : -9)
            }
            .animation(ZKAnimations.spring, value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

// MARK: - Checkbox Style (Custom checkbox with gradient)

struct ZKCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            withAnimation(ZKAnimations.springFast) {
                configuration.isOn.toggle()
            }
        }) {
            HStack(spacing: 10) {
                // Custom checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(configuration.isOn ? ZKColors.accentGradient : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 20, height: 20)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(configuration.isOn ? Color.clear : ZKColors.glassBorder, lineWidth: 1)
                        .frame(width: 20, height: 20)
                    
                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(configuration.isOn ? 1.0 : 0.95)
                
                configuration.label
                    .font(ZKTypography.body)
                    .foregroundColor(ZKColors.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sidebar Item View

struct ZKSidebarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var action: () -> Void = {}
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isSelected ? ZKColors.accentGradient : LinearGradient(colors: [ZKColors.textSecondary], startPoint: .leading, endPoint: .trailing))
                .frame(width: 24)
            
            Text(title)
                .font(ZKTypography.body)
                .foregroundColor(isSelected ? ZKColors.textPrimary : ZKColors.textSecondary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? ZKColors.accent.opacity(0.15) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? ZKColors.accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .onHover { hovering in
            withAnimation(ZKAnimations.easeOut) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Settings Group View (Glassmorphism)

struct ZKSettingsGroup<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(ZKTypography.caption)
                .foregroundColor(ZKColors.textTertiary)
                .textCase(.uppercase)
            
            GlassCard(padding: 16, cornerRadius: 12) {
                content
            }
        }
    }
}

// MARK: - Gradient Icon

struct GradientIcon: View {
    let systemName: String
    var size: CGFloat = 20
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(ZKColors.accentGradient)
    }
}

// MARK: - Pulsing Animation Modifier

struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false
    var duration: Double = 1.5
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.5 : 1.0)
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(
                Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulsing(duration: Double = 1.5) -> some View {
        modifier(PulsingModifier(duration: duration))
    }
}

// MARK: - Shake Animation Modifier

struct ShakeModifier: ViewModifier {
    var amount: CGFloat = 10
    var shakes: CGFloat = 3
    @Binding var trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: trigger ? 0 : 0)
            .modifier(ShakeEffect(shakes: trigger ? shakes : 0, amount: amount))
            .animation(ZKAnimations.spring, value: trigger)
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var amount: CGFloat
    
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(shakes * .pi * 2), y: 0))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Glass Card Preview")
                    .font(ZKTypography.headline)
                    .foregroundColor(ZKColors.textPrimary)
                
                Text("This is a glassmorphism card with blur effect")
                    .font(ZKTypography.body)
                    .foregroundColor(ZKColors.textSecondary)
            }
        }
        
        Button("Primary Button") {}
            .buttonStyle(ZKButtonStyle(style: .primary))
        
        Button("Secondary Button") {}
            .buttonStyle(ZKButtonStyle(style: .secondary))
        
        ZKSidebarItem(title: "General", icon: "gearshape", isSelected: true)
        ZKSidebarItem(title: "Advanced", icon: "slider.horizontal.3", isSelected: false)
    }
    .padding(40)
    .background(Color(hex: "1a1a2e"))
    .preferredColorScheme(.dark)
}
