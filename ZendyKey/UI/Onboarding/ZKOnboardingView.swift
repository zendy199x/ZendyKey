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
                
                // Navigation footer
                footer
            }
        }
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
        case 0:
            ZKWelcomeStep(isAnimating: isAnimating, accentColor: accentBlue)
        case 1:
            ZKPermissionStep(hasPermission: hasPermission)
        case 2:
            ZKInputMethodStep(
                selectedInputMethod: $selectedInputMethod,
                accentColor: accentBlue,
                namespace: inputMethodAnimation
            )
        default:
            EmptyView()
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            // Step indicator - animated pill style
            StepProgressIndicator(currentStep: step, totalSteps: 3, accentColor: accentBlue) { newStep in
                // Allow backward navigation to completed steps
                if canAdvanceToStep(newStep) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        step = newStep
                    }
                }
            }
            
            Spacer()
            
            // Back button (optional)
            if step > 0 {
                ZKActionButton(
                    title: "Quay lại",
                    style: .secondary
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        step -= 1
                    }
                }
            }
            
            // Primary button
            ZKActionButton(
                title: primaryButtonTitle,
                icon: step < 2 ? "arrow.right" : nil,
                style: step == 2 ? .primary : .primary
            ) {
                primaryAction()
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: primaryButtonTitle)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .background(Color.black.opacity(0.3))
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
        default: return targetStep < step  // Can always go back
        }
    }
    
    private func primaryAction() {
        switch step {
        case 0:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                step = 1
            }
        case 1:
            if hasPermission {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
    
    // MARK: - Actions
    
    private func openAccessibilitySettings() {
        // Try multiple URL schemes for compatibility
        let urlStrings = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Accessibility"
        ]
        
        for urlString in urlStrings {
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
                return
            }
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

// MARK: - Step Progress Indicator

private struct StepProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let accentColor: Color
    let onTap: (Int) -> Void
    
    private let dotSize: CGFloat = 12
    private let capsuleWidth: CGFloat = 28
    private let stepSpacing: CGFloat = 24
    
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

#Preview {
    ZKOnboardingView()
}
