//
//  ZKDesignSystem.swift
//  ZendyKey
//
//  Modern Design System with Glassmorphism, Animations, and Premium Styling
//  Supports Dark/Light/System appearance modes
//

import SwiftUI
import AppKit

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "Tự động"
    case dark = "Tối"
    case light = "Sáng"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

// MARK: - Appearance Manager

class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    
    @Published var currentMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: "appAppearanceMode")
            applyAppearance()
        }
    }
    
    private init() {
        let savedMode = UserDefaults.standard.string(forKey: "appAppearanceMode") ?? AppearanceMode.dark.rawValue
        self.currentMode = AppearanceMode(rawValue: savedMode) ?? .dark
    }
    
    func applyAppearance() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let appearance: NSAppearance?
            
            switch self.currentMode {
            case .system:
                appearance = nil
            case .dark:
                appearance = NSAppearance(named: .darkAqua)
            case .light:
                appearance = NSAppearance(named: .aqua)
            }
            
            // Smooth transition with fade animation
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.35
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.42, 0, 0.58, 1)  // easeInOut
                context.allowsImplicitAnimation = true
                
                // Apply to app level first (for new windows)
                NSApp.appearance = appearance
                
                // Force update ALL windows with animation
                for window in NSApp.windows {
                    window.appearance = appearance
                    
                    // Animate window content
                    if let contentView = window.contentView {
                        contentView.animator().alphaValue = 0.95
                    }
                }
            } completionHandler: {
                // Restore full opacity after transition
                for window in NSApp.windows {
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.15
                        context.allowsImplicitAnimation = true
                        window.contentView?.animator().alphaValue = 1.0
                    }
                    window.invalidateShadow()
                    window.contentView?.needsDisplay = true
                    window.contentView?.needsLayout = true
                }
            }
            
            // Post notification for any SwiftUI views that need to react
            NotificationCenter.default.post(name: .init("AppearanceDidChange"), object: self.currentMode)
        }
    }
}

// MARK: - Adaptive Colors (Light/Dark aware)

struct AdaptiveColors {
    @Environment(\.colorScheme) static var colorScheme
    
    // Glass backgrounds that adapt to light/dark mode
    static func glassBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03)
    }
    
    static func glassBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
    }
    
    static func glassHighlight(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.8)
    }
    
    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1E1E2E") : Color.white
    }
    
    static func surfaceBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1A1A2E") : Color(hex: "F5F5F7")  // Apple-style light gray
    }
    
    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : Color(hex: "1D1D1F")  // Apple-style dark text
    }
    
    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.7) : Color(hex: "6E6E73")  // Apple-style secondary
    }
    
    static func textTertiary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.5) : Color(hex: "86868B")  // Apple-style tertiary
    }
    
    // Main window/sidebar background
    static func sidebarBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1a1a2e") : Color(hex: "F5F5F7")  // Light sidebar
    }
    
    // Content area background gradient
    static func contentBackgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [Color(hex: "16213e"), Color(hex: "1a1a2e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.white, Color(hex: "F5F5F7")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Settings sidebar with subtle overlay
    static func sidebarBackgroundView(for scheme: ColorScheme) -> some View {
        ZStack {
            sidebarBackground(for: scheme)
            Color.white.opacity(scheme == .dark ? 0.02 : 0)
        }
    }
}

// MARK: - Visual Effect Background (Native macOS Blur)

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State
    
    init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Adaptive Glass Card

struct AdaptiveGlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let padding: CGFloat
    let cornerRadius: CGFloat
    let content: Content
    
    init(padding: CGFloat = 16, cornerRadius: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if colorScheme == .dark {
                // Dark mode: Use colored glass effect
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(0.05))
                    )
            } else {
                // Light mode: Clean white card with subtle shadow
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            
            content
                .padding(padding)
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Appearance Picker View

struct AppearancePickerView: View {
    @ObservedObject var appearanceManager = AppearanceManager.shared
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                AppearanceModeButton(
                    mode: mode,
                    isSelected: appearanceManager.currentMode == mode,
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        appearanceManager.currentMode = mode
                    }
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ZKColors.glassBackground.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ZKColors.glassBorder, lineWidth: 1)
        )
    }
}

struct AppearanceModeButton: View {
    let mode: AppearanceMode
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isHovered = false
    
    private var iconName: String {
        switch mode {
        case .system: return "circle.lefthalf.filled"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? .white : (isHovered ? ZKColors.textPrimary : ZKColors.textSecondary))
                
                Text(mode.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : (isHovered ? ZKColors.textPrimary : ZKColors.textSecondary))
            }
            .frame(width: 72, height: 64)
            .background {
                if isSelected {
                    ZKColors.accentGradient
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .matchedGeometryEffect(id: "AppearanceIndicator", in: namespace)
                        .shadow(color: ZKColors.accent.opacity(0.3), radius: 8, x: 0, y: 2)
                } else if isHovered {
                    Color.white.opacity(0.08)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
    
    static let dangerGradient = LinearGradient(
        colors: [Color.red, Color.pink],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let donationGradient = LinearGradient(
        colors: [Color.orange, Color.pink],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Glass backgrounds - ADAPTIVE to light/dark mode
    static var glassBackground: Color {
        Color(nsColor: NSColor.controlBackgroundColor).opacity(0.3)
    }
    static var glassBorder: Color {
        Color(nsColor: NSColor.separatorColor)
    }
    static var glassHighlight: Color {
        Color(nsColor: NSColor.controlAccentColor).opacity(0.15)
    }
    static var glassBackgroundElevated: Color {
        Color(nsColor: NSColor.controlBackgroundColor).opacity(0.5)
    }
    static var glassBorderStrong: Color {
        Color(nsColor: NSColor.separatorColor)
    }
    
    // Text hierarchy - ADAPTIVE to light/dark mode
    static var textPrimary: Color {
        Color(nsColor: NSColor.labelColor)
    }
    static var textSecondary: Color {
        Color(nsColor: NSColor.secondaryLabelColor)
    }
    static var textTertiary: Color {
        Color(nsColor: NSColor.tertiaryLabelColor)
    }
    
    // Accent colors
    static let accent = Color(hex: "667EEA")
    static let accentLight = Color(hex: "8B9FFF")
    
    // Glow effects (Premium enhancement)
    static let accentGlow = Color(hex: "667EEA").opacity(0.4)
    static let successGlow = Color(hex: "38EF7D").opacity(0.3)
    static let warningGlow = Color(hex: "F2994A").opacity(0.3)
    
    // Surface colors - ADAPTIVE
    static var cardBackground: Color {
        Color(nsColor: NSColor.controlBackgroundColor)
    }
    static var surfaceElevated: Color {
        Color(nsColor: NSColor.windowBackgroundColor)
    }
    static var surfacePressed: Color {
        Color(nsColor: NSColor.selectedContentBackgroundColor).opacity(0.3)
    }
    static var background: Color {
        Color(nsColor: NSColor.windowBackgroundColor)
    }
    
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
    static let springSnappy = Animation.spring(response: 0.2, dampingFraction: 0.85)
    static let easeOut = Animation.easeOut(duration: 0.2)
    static let easeInOut = Animation.easeInOut(duration: 0.25)
    static let smooth = Animation.interactiveSpring(response: 0.35, dampingFraction: 0.75)
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
    
    // Icon text (for VI, EN, etc.)
    static let iconText = Font.system(size: 14, weight: .bold, design: .rounded)
    static let iconTextSmall = Font.system(size: 12, weight: .bold, design: .rounded)
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
                    .fill(isHovered ? ZKColors.glassBackground : Color.clear)
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

// MARK: - Press Effect Modifier (Premium micro-interaction)

struct PressEffectModifier: ViewModifier {
    @GestureState private var isPressed = false
    var scaleEffect: CGFloat = 0.97
    var brightnessChange: Double = -0.05
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scaleEffect : 1.0)
            .brightness(isPressed ? brightnessChange : 0)
            .animation(ZKAnimations.springSnappy, value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

extension View {
    func pressEffect(scale: CGFloat = 0.97, brightness: Double = -0.05) -> some View {
        modifier(PressEffectModifier(scaleEffect: scale, brightnessChange: brightness))
    }
}

// MARK: - Glow Effect Modifier (Premium enhancement)

struct GlowEffectModifier: ViewModifier {
    var color: Color = ZKColors.accent
    var radius: CGFloat = 10
    var intensity: Double = 0.6
    @State private var isGlowing = false
    var animated: Bool = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(animated ? (isGlowing ? intensity : intensity * 0.5) : intensity), radius: radius)
            .onAppear {
                if animated {
                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isGlowing.toggle()
                    }
                }
            }
    }
}

extension View {
    func glowEffect(color: Color = ZKColors.accent, radius: CGFloat = 10, intensity: Double = 0.6, animated: Bool = false) -> some View {
        modifier(GlowEffectModifier(color: color, radius: radius, intensity: intensity, animated: animated))
    }
}

// MARK: - Animated Toggle Style

struct ZKToggleStyle: ToggleStyle {
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(ZKTypography.body)
            
            Spacer()
            
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                // Track (background)
                Capsule()
                    .fill(
                        configuration.isOn
                            ? AnyShapeStyle(ZKColors.accentGradient)
                            : AnyShapeStyle(Color(nsColor: .separatorColor).opacity(0.3))
                    )
                    .frame(width: 50, height: 25)
                    .overlay(
                        Capsule()
                            .stroke(
                                configuration.isOn
                                    ? Color.white.opacity(0.15)
                                    : Color.white.opacity(0.08),
                                lineWidth: 0.5
                            )
                    )
                    // Glow effect when on
                    .shadow(
                        color: configuration.isOn ? ZKColors.accent.opacity(0.3) : .clear,
                        radius: isPressed ? 8 : 4,
                        x: 0,
                        y: 0
                    )
                
                // Pill (knob) - elongates when pressed like macOS
                Capsule()
                    .fill(.regularMaterial)
                    .overlay(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.15), radius: isPressed ? 4 : 2, x: 0, y: isPressed ? 3 : 1)
                    .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
                    .frame(width: isPressed ? 28 : 21, height: 21)
                    .padding(.horizontal, 2)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0), value: configuration.isOn)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            isPressed = false
                        }
                        configuration.isOn.toggle()
                    }
            )
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
                        .fill(configuration.isOn ? ZKColors.accentGradient : LinearGradient(colors: [ZKColors.glassBackground], startPoint: .leading, endPoint: .trailing))
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
    var namespace: Namespace.ID?
    var action: () -> Void = {}
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? LinearGradient(colors: [.white], startPoint: .leading, endPoint: .trailing) : (isHovered ? ZKColors.accentGradient : LinearGradient(colors: [ZKColors.textSecondary], startPoint: .leading, endPoint: .trailing)))
                    .frame(width: 24)
                
                Text(title)
                    .font(ZKTypography.body.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (isHovered ? ZKColors.textPrimary : ZKColors.textSecondary))
                
                Spacer()
            }
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    ZKColors.accentGradient
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .matchedGeometryEffect(id: "SidebarSelectedIndicator", in: namespace ?? Namespace().wrappedValue)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                }
            }
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
    .background(Color(nsColor: .windowBackgroundColor))
}
