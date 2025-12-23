//
//  ZKOnboardingView.swift
//  ZendyKey
//
//  Premium onboarding flow with glassmorphism design
//  Modern animations and smooth transitions
//

import SwiftUI

/// Check if onboarding has been completed
func hasCompletedOnboarding() -> Bool {
    return UserDefaults.standard.bool(forKey: "onboardingCompleted")
}

/// Mark onboarding as completed
func markOnboardingCompleted() {
    UserDefaults.standard.set(true, forKey: "onboardingCompleted")
}

// MARK: - Notification for Onboarding Completion

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("ZendyKeyOnboardingCompleted")
}

// MARK: - Main Onboarding View

struct ZKOnboardingView: View {
    @State private var step = 0
    @State private var hasPermission = false
    @State private var hadPermissionOnStart = false  // Stale permission detection
    @State private var selectedInputMethod: InputMethod = .telex
    @State private var isAnimating = false
    @Namespace private var inputMethodAnimation
    
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    // Design constants
    private let accentRed = Color(red: 0.85, green: 0.15, blue: 0.15)
    private let accentBlue = Color(red: 0.2, green: 0.5, blue: 1.0)
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0f0f23"), Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                content
                    .frame(maxHeight: .infinity)
                
                // Footer
                footer
            }
        }
        .frame(width: 600, height: 680)
        .onAppear {
            let initialPermission = AXIsProcessTrusted()
            hasPermission = initialPermission
            hadPermissionOnStart = initialPermission  // Track if permission was already granted
            withAnimation(.easeOut(duration: 0.3)) {
                isAnimating = true
            }
        }
        .onReceive(timer) { _ in
            // Always check and update permission status
            let newPermission = AXIsProcessTrusted()
            
            // Always update with animation for smooth transitions
            withAnimation(.easeInOut(duration: 0.2)) {
                hasPermission = newPermission
            }
            
            // If on step 3 and permission was revoked, go back to step 2
            if step == 2 && !newPermission {
                withAnimation(.easeInOut(duration: 0.3)) {
                    step = 1
                }
            }
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        switch step {
        case 0: welcomeStep
        case 1: permissionStep
        case 2: inputMethodStep
        default: EmptyView()
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            // Step indicator - animated pill style
            StepProgressIndicator(currentStep: step, totalSteps: 3, accentColor: accentBlue) { newStep in
                // Allow going back to any visited step OR forward to next available step
                if newStep < step || (newStep == step + 1 && canAdvanceToStep(newStep)) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        step = newStep
                    }
                }
            }
            
            Spacer()
            
            // Back button
            if step > 0 {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        step -= 1
                    }
                }) {
                    Text("Quay lại")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            
            // Primary button
            primaryButton
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .background(Color.black.opacity(0.3))
    }
    
    @ViewBuilder
    private var primaryButton: some View {
        Button(action: primaryAction) {
            HStack(spacing: 8) {
                Text(primaryButtonTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .id("buttonTitle_\(primaryButtonTitle)") // Force view refresh for animation
                
                if step < 2 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(ZKColors.accentGradient)
            .clipShape(Capsule())
            .shadow(color: ZKColors.accent.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: primaryButtonTitle)
    }
    
    private var primaryButtonTitle: String {
        switch step {
        case 0: return "Tiếp tục"
        case 1: return hasPermission ? "Tiếp tục" : "Mở System Settings"
        case 2: return "Hoàn tất"
        default: return ""
        }
    }
    
    private func canAdvanceToStep(_ targetStep: Int) -> Bool {
        switch targetStep {
        case 1: return true  // Can always go to permission step
        case 2: return hasPermission  // Can only go to step 3 if permission granted
        default: return false
        }
    }
    
    private func primaryAction() {
        switch step {
        case 0:
            withAnimation(.easeOut(duration: 0.25)) {
                step = 1
            }
        case 1:
            if hasPermission {
                // Permission already granted, continue to next step
                withAnimation(.easeOut(duration: 0.25)) {
                    step = 2
                }
            } else {
                // Open System Settings
                openAccessibilitySettings()
            }
        case 2:
            finish()
        default:
            break
        }
    }
    
    // MARK: - Welcome Step
    
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Logo with glow
            ZStack {
                Circle()
                    .fill(accentBlue.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                if let logo = NSImage(named: "ZendyKeyLogo") {
                    Image(nsImage: logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: accentBlue.opacity(0.5), radius: 20)
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(accentBlue)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("ZK")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .scaleEffect(isAnimating ? 1 : 0.8)
            .opacity(isAnimating ? 1 : 0)
            
            VStack(spacing: 8) {
                Text("Chào mừng bạn đến với")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("ZendyKey")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("Bộ gõ tiếng Việt thông minh cho MacOS")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Features
            VStack(spacing: 12) {
                FeatureRow(icon: "keyboard.fill", title: "Telex - VNI - VIQR & Simple Telex", desc: "Hỗ trợ đầy đủ các kiểu gõ", color: accentBlue)
                FeatureRow(icon: "sparkles", title: "Thông minh", desc: "Hỗ trợ nhiều tính năng thông minh", color: .orange)
                FeatureRow(icon: "bolt.fill", title: "Siêu nhanh", desc: "Tối ưu hiệu năng cao nhất", color: .green)
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Permission Step
    
    private var permissionStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)
                
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                    )
            }
            
            VStack(spacing: 8) {
                Text("Cấp quyền Accessibility")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("ZendyKey cần quyền này để nhận phím từ bàn phím")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            // Steps
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(number: "1", text: "Mở Privacy & Security → Accessibility")
                InstructionRow(number: "2", text: "Tìm và bật công tắc bên cạnh ZendyKey")
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            
            // Permission status with animation
            if hasPermission {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Đã cấp quyền thành công!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Input Method Step
    
    private var inputMethodStep: some View {
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
                    accentColor: accentBlue,
                    namespace: inputMethodAnimation
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
                    accentColor: accentBlue,
                    namespace: inputMethodAnimation
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
                    accentColor: accentBlue,
                    namespace: inputMethodAnimation
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
    
    // MARK: - Actions
    
    private func openAccessibilitySettings() {
        // Try multiple URL schemes for compatibility
        let urlStrings = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        ]
        
        for urlString in urlStrings {
            if let url = URL(string: urlString) {
                let result = NSWorkspace.shared.open(url)
                if result {
                    return
                }
            }
        }
        
        // Fallback: open System Settings directly
        if let url = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func finish() {
        // Save input method to UserDefaults.standard (safe, no App Group access during onboarding)
        UserDefaults.standard.set(selectedInputMethod.rawValue, forKey: "ZendyKey.inputMethod")
        
        // Mark onboarding as completed
        markOnboardingCompleted()
        
        // Post notification for observers (like GoNhanh pattern)
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
        
        // Close window simply - like GoNhanh
        NSApp.keyWindow?.close()
    }
}

// MARK: - Supporting Views

// Animated step progress indicator - capsule slides smoothly to current step
private struct StepProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let accentColor: Color
    let onTap: (Int) -> Void
    
    private let dotSize: CGFloat = 12
    private let capsuleWidth: CGFloat = 28
    private let stepSpacing: CGFloat = 24  // Equal spacing between step centers
    
    // Capsule offset based on current step - equal spacing
    private var capsuleOffset: CGFloat {
        return CGFloat(currentStep) * stepSpacing
    }
    
    // Total width needed
    private var totalWidth: CGFloat {
        return capsuleWidth + CGFloat(totalSteps - 1) * stepSpacing
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Sliding capsule indicator (active step) with gradient
            Capsule()
                .fill(ZKColors.accentGradient)
                .frame(width: capsuleWidth, height: dotSize)
                .offset(x: capsuleOffset)
            
            // Only show dots for VISITED steps (not current, not future)
            ForEach(0..<totalSteps, id: \.self) { index in
                if index < currentStep {
                    // Visited step - clickable dot with gradient
                    Button(action: {
                        onTap(index)
                    }) {
                        Circle()
                            .fill(ZKColors.accentGradient)
                            .opacity(0.6)
                            .frame(width: dotSize, height: dotSize)
                    }
                    .buttonStyle(.plain)
                    .offset(x: CGFloat(index) * stepSpacing + (capsuleWidth - dotSize) / 2)
                } else if index > currentStep {
                    // Future step - just a placeholder for click area (invisible)
                    Button(action: {
                        onTap(index)
                    }) {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: dotSize, height: dotSize)
                    }
                    .buttonStyle(.plain)
                    .offset(x: CGFloat(index) * stepSpacing + (capsuleWidth - dotSize) / 2)
                }
                // Current step has no dot - covered by capsule
            }
        }
        .frame(width: totalWidth, height: dotSize)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
    }
}




private struct FeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
    }
}

private struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.orange)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// Input method option card with matchedGeometryEffect animation
private struct InputMethodOptionCard: View {
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
                            .foregroundStyle(ZKColors.accentGradient)
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

#Preview {
    ZKOnboardingView()
}
