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

// MARK: - Main Onboarding View

struct ZKOnboardingView: View {
    @State private var step = 0
    @State private var hasPermission = false
    @State private var selectedInputMethod: InputMethod = .telex
    @State private var isAnimating = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var onComplete: (() -> Void)?
    
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
        .frame(width: 520, height: 480)
        .onAppear {
            hasPermission = AXIsProcessTrusted()
            withAnimation(.spring(response: 0.6)) {
                isAnimating = true
            }
        }
        .onReceive(timer) { _ in
            hasPermission = AXIsProcessTrusted()
            if step == 1 && hasPermission {
                withAnimation(.spring(response: 0.5)) {
                    step = 2
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
            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? accentBlue : Color.white.opacity(0.2))
                        .frame(width: i == step ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.4), value: step)
                }
            }
            
            Spacer()
            
            // Back button
            if step > 0 {
                Button(action: {
                    withAnimation(.spring(response: 0.4)) {
                        step -= 1
                    }
                }) {
                    Text("Quay lại")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            // Primary button
            primaryButton
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(Color.black.opacity(0.2))
    }
    
    @ViewBuilder
    private var primaryButton: some View {
        Button(action: primaryAction) {
            HStack(spacing: 8) {
                Text(primaryButtonTitle)
                    .font(.system(size: 14, weight: .semibold))
                
                if step < 2 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [accentBlue, accentBlue.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(10)
            .shadow(color: accentBlue.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var primaryButtonTitle: String {
        switch step {
        case 0: return "Tiếp tục"
        case 1: return "Mở System Settings"
        case 2: return "Hoàn tất"
        default: return ""
        }
    }
    
    private func primaryAction() {
        switch step {
        case 0:
            withAnimation(.spring(response: 0.5)) {
                step = 1
            }
        case 1:
            openAccessibilitySettings()
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
                Text("Chào mừng đến với")
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
                
                Text("Bộ gõ tiếng Việt thông minh cho macOS")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Features
            VStack(spacing: 12) {
                FeatureRow(icon: "keyboard.fill", title: "Telex & VNI", desc: "Hỗ trợ đầy đủ các kiểu gõ", color: accentBlue)
                FeatureRow(icon: "sparkles", title: "Thông minh", desc: "Tự động khôi phục tiếng Anh", color: .orange)
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
            
            // Permission status
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
            
            // Input method options
            VStack(spacing: 12) {
                InputMethodCard(
                    title: "Telex",
                    description: "aa → â, aw → ă, s → sắc",
                    example: "Việt Nam → Vieetj Nam",
                    isSelected: selectedInputMethod == .telex,
                    accentColor: accentBlue
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedInputMethod = .telex
                    }
                }
                
                InputMethodCard(
                    title: "VNI",
                    description: "a6 → â, a8 → ă, 1 → sắc",
                    example: "Việt Nam → Vie6t1 Nam",
                    isSelected: selectedInputMethod == .vni,
                    accentColor: accentBlue
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedInputMethod = .vni
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
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func finish() {
        // Save to shared settings (safe method)
        ZKSharedSettings.shared.inputMethod = selectedInputMethod.rawValue
        
        // Mark onboarding as completed
        markOnboardingCompleted()
        
        // Notify completion
        onComplete?()
        
        // Close window safely on main thread
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow {
                window.close()
            }
        }
    }
}

// MARK: - Supporting Views

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

private struct InputMethodCard: View {
    let title: String
    let description: String
    let example: String
    let isSelected: Bool
    let accentColor: Color
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
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? accentColor : .white.opacity(0.3))
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
