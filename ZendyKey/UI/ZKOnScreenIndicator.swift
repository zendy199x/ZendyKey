//
//  ZKOnScreenIndicator.swift
//  ZendyKey
//
//  Premium on-screen indicator for mode changes
//  Modern glassmorphism design with smooth animations
//

import SwiftUI
import AppKit

// MARK: - Indicator Types

enum ZKIndicatorType {
    case language(isVietnamese: Bool)
    case inputMethod(InputMethod)
    case codeTable(CodeTable)
    
    var displayText: String {
        switch self {
        case .language(let isVietnamese):
            return isVietnamese ? "VI" : "EN"
        case .inputMethod(let method):
            return method.shortDisplayName
        case .codeTable(let table):
            return table.shortDisplayName
        }
    }
    
    var titleText: String {
        switch self {
        case .language(let isVietnamese):
            return isVietnamese ? "Tiếng Việt" : "English"
        case .inputMethod(let method):
            return method.displayName
        case .codeTable(let table):
            return table.displayName
        }
    }
    
    var iconName: String {
        switch self {
        case .language:
            return "globe"
        case .inputMethod:
            return "keyboard"
        case .codeTable:
            return "tablecells"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .language(let isVietnamese):
            return isVietnamese ? Color(red: 0.85, green: 0.15, blue: 0.15) : Color.orange
        case .inputMethod:
            return Color(red: 0.2, green: 0.7, blue: 0.5) // Teal
        case .codeTable:
            return Color(red: 0.5, green: 0.3, blue: 0.9) // Purple
        }
    }
    
    var ringColor: Color {
        switch self {
        case .language(let isVietnamese):
            return isVietnamese ? Color(red: 0.85, green: 0.3, blue: 0.15) : Color.orange
        case .inputMethod:
            return Color.teal
        case .codeTable:
            return Color.purple
        }
    }
}

// MARK: - Input Method Short Name Extension

extension InputMethod {
    var shortDisplayName: String {
        switch self {
        case .telex: return "Telex"
        case .vni: return "VNI"
        case .viqr: return "VIQR"
        case .simpleTelex1: return "ST1"
        case .simpleTelex2: return "ST2"
        }
    }
}

// MARK: - Code Table Short Name Extension

extension CodeTable {
    var shortDisplayName: String {
        switch self {
        case .unicode: return "UNI"
        case .tcvn3: return "TCVN3"
        case .vniWindows: return "VNI"
        case .unicodeCompound: return "UNC"
        case .vietnameseLocaleCP1258: return "CP1258"
        }
    }
}

/// On-screen indicator controller
class ZKOnScreenIndicatorController {
    static let shared = ZKOnScreenIndicatorController()
    
    private var indicatorWindow: NSWindow?
    private var hostingView: NSHostingView<ZKOnScreenIndicatorView>?
    private var hideTimer: Timer?
    
    private init() {}
    
    /// Show the indicator with the current mode (legacy compatibility)
    func show(isVietnamese: Bool) {
        show(type: .language(isVietnamese: isVietnamese))
    }
    
    /// Show the indicator with input method
    func show(inputMethod: InputMethod) {
        show(type: .inputMethod(inputMethod))
    }
    
    /// Show the indicator with code table
    func show(codeTable: CodeTable) {
        show(type: .codeTable(codeTable))
    }
    
    /// Show the indicator with specific type
    func show(type: ZKIndicatorType) {
        DispatchQueue.main.async { [weak self] in
            self?.showIndicator(type: type)
        }
    }
    
    /// Hide the indicator
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.hideIndicator()
        }
    }
    
    private func showIndicator(type: ZKIndicatorType) {
        // Cancel any existing hide timer
        hideTimer?.invalidate()
        
        let windowWidth: CGFloat = 160
        let windowHeight: CGFloat = 160
        
        // Create window if needed
        if indicatorWindow == nil {
            createIndicatorWindow()
        }
        
        // Check if window is already visible
        let isAlreadyVisible = indicatorWindow?.alphaValue ?? 0 > 0.5
        
        // Update content with crossfade animation if already visible
        if isAlreadyVisible {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                context.allowsImplicitAnimation = true
                hostingView?.rootView = ZKOnScreenIndicatorView(type: type)
            }
        } else {
            hostingView?.rootView = ZKOnScreenIndicatorView(type: type)
        }
        
        // Position window at top center of main screen
        if let screen = NSScreen.main {
            let screenCenter = screen.frame.width / 2
            let yPosition = screen.frame.height - windowHeight - 100 // 100pt from top
            
            indicatorWindow?.setFrame(
                NSRect(x: screenCenter - windowWidth / 2,
                       y: yPosition,
                       width: windowWidth,
                       height: windowHeight),
                display: true
            )
        }
        
        // Only animate fade-in if not already visible
        if !isAlreadyVisible {
            indicatorWindow?.alphaValue = 0
            indicatorWindow?.orderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                context.allowsImplicitAnimation = true
                indicatorWindow?.animator().alphaValue = 1
            }
        }
        
        // Auto-hide after 1.5 seconds
        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.hideIndicator()
        }
    }
    
    private func hideIndicator() {
        hideTimer?.invalidate()
        hideTimer = nil
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            indicatorWindow?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.indicatorWindow?.orderOut(nil)
        })
    }
    
    private func createIndicatorWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 160),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .popUpMenu
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false  // Disabled to avoid black border artifact
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let view = ZKOnScreenIndicatorView(type: .language(isVietnamese: true))
        let hostingView = NSHostingView(rootView: view)
        window.contentView = hostingView
        
        self.hostingView = hostingView
        self.indicatorWindow = window
    }
}

// MARK: - Premium Indicator View with Glass Background

struct ZKOnScreenIndicatorView: View {
    let type: ZKIndicatorType
    
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with pulsing ring
            ZStack {
                // Outer pulsing ring (breathing animation)
                Circle()
                    .stroke(type.ringColor.opacity(0.3), lineWidth: 3)
                    .frame(width: 90, height: 90)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)
                    .opacity(isPulsing ? 0.0 : 0.6)
                
                // Second pulsing ring (delayed)
                Circle()
                    .stroke(type.ringColor.opacity(0.4), lineWidth: 2)
                    .frame(width: 85, height: 85)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                    .opacity(isPulsing ? 0.2 : 0.8)
                
                // Main ring border
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [type.ringColor, type.ringColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 75, height: 75)
                
                // Inner filled circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [type.accentColor, type.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                    .shadow(color: type.accentColor.opacity(0.5), radius: 8, x: 0, y: 4)
                
                // Content inside circle
                VStack(spacing: 2) {
                    Image(systemName: type.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(type.displayText)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            // Title below
            Text(type.titleText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 140)  // Fixed width to prevent layout changes
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            // Dark glass background for consistent appearance
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .environment(\.colorScheme, .dark)  // Force dark material
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
        .onAppear {
            // Start pulsing animation
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
        .onDisappear {
            isPulsing = false
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        HStack(spacing: 30) {
            ZKOnScreenIndicatorView(type: .language(isVietnamese: true))
            ZKOnScreenIndicatorView(type: .language(isVietnamese: false))
        }
        HStack(spacing: 30) {
            ZKOnScreenIndicatorView(type: .inputMethod(.telex))
            ZKOnScreenIndicatorView(type: .codeTable(.unicode))
        }
    }
    .padding(50)
    .background(Color.black.opacity(0.5))
}
