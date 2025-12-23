//
//  ZKOnScreenIndicator.swift
//  ZendyKey
//
//  Premium on-screen indicator for mode changes
//  Modern glassmorphism design with smooth animations
//

import SwiftUI
import AppKit

/// On-screen indicator controller
class ZKOnScreenIndicatorController {
    static let shared = ZKOnScreenIndicatorController()
    
    private var indicatorWindow: NSWindow?
    private var hostingView: NSHostingView<ZKOnScreenIndicatorView>?
    private var hideTimer: Timer?
    
    private init() {}
    
    /// Show the indicator with the current mode
    func show(isVietnamese: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.showIndicator(isVietnamese: isVietnamese)
        }
    }
    
    /// Hide the indicator
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.hideIndicator()
        }
    }
    
    private func showIndicator(isVietnamese: Bool) {
        // Cancel any existing hide timer
        hideTimer?.invalidate()
        
        // Create or update the window
        if indicatorWindow == nil {
            createIndicatorWindow()
        }
        
        // Update content
        hostingView?.rootView = ZKOnScreenIndicatorView(isVietnamese: isVietnamese)
        
        // Position window at top center of main screen
        if let screen = NSScreen.main {
            let windowSize: CGFloat = 100
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
        
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let view = ZKOnScreenIndicatorView(isVietnamese: true)
        let hostingView = NSHostingView(rootView: view)
        window.contentView = hostingView
        
        self.hostingView = hostingView
        self.indicatorWindow = window
    }
}

// MARK: - Premium Indicator View

struct ZKOnScreenIndicatorView: View {
    let isVietnamese: Bool
    
    // Flag colors
    private var borderColor: Color {
        isVietnamese ? Color(red: 0.85, green: 0.15, blue: 0.15) : Color(red: 0.0, green: 0.4, blue: 0.8)
    }
    
    private var glowColor: Color {
        isVietnamese ? Color.red.opacity(0.5) : Color.blue.opacity(0.5)
    }
    
    private var borderGradient: AngularGradient {
        let colors = isVietnamese
            ? [Color(red: 0.85, green: 0.15, blue: 0.15), Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 0.85, green: 0.15, blue: 0.15)]
            : [Color(red: 0.0, green: 0.4, blue: 0.8), Color(red: 0.3, green: 0.6, blue: 1.0), Color(red: 0.0, green: 0.4, blue: 0.8)]
        return AngularGradient(colors: colors, center: .center)
    }
    
    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(glowColor, lineWidth: 8)
                .blur(radius: 8)
                .frame(width: 80, height: 80)
            
            // Main ring with gradient
            Circle()
                .stroke(borderGradient, lineWidth: 4)
                .frame(width: 80, height: 80)
            
            // Inner subtle glass effect
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 72, height: 72)
                .blur(radius: 1)
            
            // Content
            VStack(spacing: 4) {
                // Logo
                if let logo = NSImage(named: "ZendyKeyLogo") {
                    Image(nsImage: logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Text(isVietnamese ? "🇻🇳" : "🇬🇧")
                        .font(.system(size: 28))
                }
                
                // Label - same color as border for visibility
                Text(isVietnamese ? "VI" : "EN")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(borderColor)
            }
        }
        .frame(width: 90, height: 90)
    }
}

#Preview {
    HStack(spacing: 30) {
        ZKOnScreenIndicatorView(isVietnamese: true)
        ZKOnScreenIndicatorView(isVietnamese: false)
    }
    .padding(50)
    .background(Color.black.opacity(0.3))
}
