//
//  ZKStatusBarPopoverView.swift
//  ZendyKey
//
//  Modern glassmorphism popover view for status bar
//

import SwiftUI

// MARK: - Status Bar Popover View

struct ZKStatusBarPopoverView: View {
    @ObservedObject var viewModel: ZKStatusBarViewModel
    @State private var hoveredSection: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with app info
            headerSection
            
            Divider()
                .background(ZKColors.glassBorder)
            
            // Main toggle section
            toggleSection
                .padding(.vertical, 12)
            
            Divider()
                .background(ZKColors.glassBorder)
            
            // Quick statistics section
            quickStatsSection
                .padding(.vertical, 8)
            
            Divider()
                .background(ZKColors.glassBorder)
            
            // Quick settings
            settingsSection
                .padding(.vertical, 8)
            
            Divider()
                .background(ZKColors.glassBorder)
            
            // Actions
            actionsSection
                .padding(.vertical, 8)
        }
        .frame(width: 280)
        .background(
            ZStack {
                // Dark background
                Color(hex: "1a1a2e")
                
                // Glass effect
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [Color.white.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ZKColors.glassBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            // App icon
            Image("ZendyKeyLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ZendyKey")
                    .font(ZKTypography.headline)
                    .foregroundColor(ZKColors.textPrimary)
                
                HStack(spacing: 6) {
                    // Status indicator
                    Circle()
                        .fill(viewModel.isVietnameseEnabled ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    
                    Text(viewModel.isVietnameseEnabled ? "Tiếng Việt" : "English")
                        .font(ZKTypography.caption)
                        .foregroundColor(ZKColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Settings button
            Button(action: { viewModel.openPreferences() }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundColor(ZKColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
    
    // MARK: - Toggle Section
    
    private var toggleSection: some View {
        VStack(spacing: 12) {
            // Main Vietnamese toggle
            Button(action: { viewModel.toggleVietnamese() }) {
                HStack(spacing: 14) {
                    // Animated toggle icon
                    ZStack {
                        Circle()
                            .fill(viewModel.isVietnameseEnabled ? ZKColors.accentGradient : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 44, height: 44)
                        
                        Text(viewModel.isVietnameseEnabled ? "V" : "E")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(viewModel.isVietnameseEnabled ? 1.0 : 0.95)
                    .animation(ZKAnimations.spring, value: viewModel.isVietnameseEnabled)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.isVietnameseEnabled ? "Đang bật" : "Đã tắt")
                            .font(ZKTypography.body)
                            .foregroundColor(ZKColors.textPrimary)
                        
                        Text("Nhấn \(viewModel.hotkeyDisplay) để chuyển")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    // Toggle switch
                    Toggle("", isOn: Binding(
                        get: { viewModel.isVietnameseEnabled },
                        set: { _ in viewModel.toggleVietnamese() }
                    ))
                    .toggleStyle(ZKToggleStyle())
                    .labelsHidden()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ZKColors.glassBackground)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(ZKColors.accentGradient)
                
                Text("Tốc độ gõ")
                    .font(ZKTypography.caption)
                    .foregroundColor(ZKColors.textSecondary)
                
                Spacer()
                
                Button(action: { viewModel.openStatistics() }) {
                    Text("Xem chi tiết")
                        .font(.system(size: 10))
                        .foregroundColor(ZKColors.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            
            // Speed display
            HStack(spacing: 16) {
                // WPM
                VStack(alignment: .center, spacing: 2) {
                    Text("\(Int(ZKStatisticsManager.shared.wordsPerMinute))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "38EF7D"), Color(hex: "11998E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("từ/phút")
                        .font(.system(size: 9))
                        .foregroundColor(ZKColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                // CPM
                VStack(alignment: .center, spacing: 2) {
                    Text("\(Int(ZKStatisticsManager.shared.charsPerMinute))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("ký tự/phút")
                        .font(.system(size: 9))
                        .foregroundColor(ZKColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                // Today keystrokes
                VStack(alignment: .center, spacing: 2) {
                    Text(formatCompactNumber(ZKStatisticsManager.shared.todayKeystrokes))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(ZKColors.textPrimary)
                    
                    Text("hôm nay")
                        .font(.system(size: 9))
                        .foregroundColor(ZKColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.08), Color.blue.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .padding(.horizontal, 12)
        }
    }
    
    private func formatCompactNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(spacing: 4) {
            // Input Method
            PopoverMenuItem(
                icon: "keyboard",
                title: "Kiểu gõ",
                value: viewModel.currentInputMethod.displayName,
                isHovered: hoveredSection == "inputMethod"
            ) {
                // This could open a submenu or picker
            }
            .onHover { hovering in
                withAnimation(ZKAnimations.springFast) {
                    hoveredSection = hovering ? "inputMethod" : nil
                }
            }
            
            // Code Table
            PopoverMenuItem(
                icon: "doc.text",
                title: "Bảng mã",
                value: viewModel.currentCodeTable.displayName,
                isHovered: hoveredSection == "codeTable"
            ) {
                // This could open a submenu or picker
            }
            .onHover { hovering in
                withAnimation(ZKAnimations.springFast) {
                    hoveredSection = hovering ? "codeTable" : nil
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 4) {
            PopoverActionButton(
                icon: "text.quote",
                title: "Quản lý Macro",
                isHovered: hoveredSection == "macro"
            ) {
                viewModel.openMacroManagement()
            }
            .onHover { hovering in
                withAnimation(ZKAnimations.springFast) {
                    hoveredSection = hovering ? "macro" : nil
                }
            }
            
            PopoverActionButton(
                icon: "arrow.2.squarepath",
                title: "Công cụ chuyển đổi",
                isHovered: hoveredSection == "convert"
            ) {
                viewModel.openZKConvertTool()
            }
            .onHover { hovering in
                withAnimation(ZKAnimations.springFast) {
                    hoveredSection = hovering ? "convert" : nil
                }
            }
            
            Divider()
                .background(ZKColors.glassBorder)
                .padding(.vertical, 4)
            
            PopoverActionButton(
                icon: "power",
                title: "Thoát ZendyKey",
                isDestructive: true,
                isHovered: hoveredSection == "quit"
            ) {
                viewModel.quit()
            }
            .onHover { hovering in
                withAnimation(ZKAnimations.springFast) {
                    hoveredSection = hovering ? "quit" : nil
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Popover Menu Item

struct PopoverMenuItem: View {
    let icon: String
    let title: String
    let value: String
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                GradientIcon(systemName: icon, size: 14)
                
                Text(title)
                    .font(ZKTypography.body)
                    .foregroundColor(ZKColors.textPrimary)
                
                Spacer()
                
                Text(value)
                    .font(ZKTypography.caption)
                    .foregroundColor(ZKColors.textSecondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(ZKColors.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? ZKColors.glassBackground : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Popover Action Button

struct PopoverActionButton: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isDestructive ? .red : (isHovered ? Color.white : ZKColors.textSecondary))
                    .frame(width: 20)
                
                Text(title)
                    .font(ZKTypography.body)
                    .foregroundColor(isDestructive ? .red : ZKColors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? (isDestructive ? Color.red.opacity(0.15) : ZKColors.glassBackground) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Visual Effect Blur (for NSVisualEffectView)

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Preview

#if DEBUG
struct ZKStatusBarPopoverView_Previews: PreviewProvider {
    static var previews: some View {
        ZKStatusBarPopoverView(viewModel: ZKStatusBarViewModel(keyboardHandler: nil, eventTapManager: nil))
    }
}
#endif
