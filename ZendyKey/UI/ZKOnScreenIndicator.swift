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
    
    var borderColor: Color {
        switch self {
        case .language(let isVietnamese):
            return isVietnamese ? Color(red: 0.85, green: 0.15, blue: 0.15) : Color(red: 0.0, green: 0.4, blue: 0.8)
        case .inputMethod:
            return Color(red: 0.2, green: 0.7, blue: 0.5) // Teal
        case .codeTable:
            return Color(red: 0.5, green: 0.3, blue: 0.9) // Purple
        }
    }
    
    var glowColor: Color {
        switch self {
        case .language(let isVietnamese):
            return isVietnamese ? Color.red.opacity(0.5) : Color.blue.opacity(0.5)
        case .inputMethod:
            return Color.purple.opacity(0.5)
        case .codeTable:
            return Color.teal.opacity(0.5)
        }
    }
    
    var borderGradient: AngularGradient {
        let baseColor = borderColor
        let colors = [baseColor, baseColor.opacity(0.7), baseColor]
        return AngularGradient(colors: colors, center: .center)
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
        
        let windowSize: CGFloat = 100
        
        // Create or update the window
        if indicatorWindow == nil {
            createIndicatorWindow()
        }
        
        // Update content
        hostingView?.rootView = ZKOnScreenIndicatorView(type: type)
        
        // Position window at top center of main screen
        if let screen = NSScreen.main {
            let screenCenter = screen.frame.width / 2
            let yPosition = screen.frame.height - windowSize - 120 // 120pt from top
            
            indicatorWindow?.setFrame(
                NSRect(x: screenCenter - windowSize / 2,
                       y: yPosition,
                       width: windowSize,
                       height: windowSize),
                display: true
            )
        }
        
        // Show window with spring animation
        indicatorWindow?.alphaValue = 0
        indicatorWindow?.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            context.allowsImplicitAnimation = true
            indicatorWindow?.animator().alphaValue = 1
        }
        
        // Auto-hide after 1.2 seconds
        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
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
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .popUpMenu
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let view = ZKOnScreenIndicatorView(type: .language(isVietnamese: true))
        let hostingView = NSHostingView(rootView: view)
        window.contentView = hostingView
        
        self.hostingView = hostingView
        self.indicatorWindow = window
    }
}

// MARK: - Premium Indicator View

struct ZKOnScreenIndicatorView: View {
    let type: ZKIndicatorType
    
    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(type.glowColor, lineWidth: 8)
                .blur(radius: 8)
                .frame(width: 80, height: 80)
            
            // Main ring with gradient
            Circle()
                .stroke(type.borderGradient, lineWidth: 4)
                .frame(width: 80, height: 80)
            
            // Inner subtle glass effect
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 72, height: 72)
                .blur(radius: 1)
            
            // Content
            VStack(spacing: 2) {
                // Logo
                if let logo = NSImage(named: "ZendyKeyLogo") {
                    Image(nsImage: logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // Main text (VI/EN, Telex, Unicode, etc.)
                Text(type.displayText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(type.borderColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(width: 90, height: 90)
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
            ZKOnScreenIndicatorView(type: .inputMethod(.vni))
        }
        HStack(spacing: 30) {
            ZKOnScreenIndicatorView(type: .codeTable(.unicode))
            ZKOnScreenIndicatorView(type: .codeTable(.tcvn3))
        }
    }
    .padding(50)
    .background(Color.black.opacity(0.3))
}
