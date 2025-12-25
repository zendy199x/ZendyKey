//
//  ZKMenuBarPopover.swift
//  ZendyKey
//
//  Modern glassmorphism menu with adaptive dark/light/system mode support
//  Matches ZKSettingsView sidebar design with hover effects and animations
//

import SwiftUI
import AppKit

// MARK: - Modern Menu View

struct ZKModernMenuView: View {
    @ObservedObject var viewModel: ZKStatusBarViewModel
    @ObservedObject private var appearanceManager = AppearanceManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var hoveredItem: String?
    @State private var expandedSubmenu: String?
    
    var onDismiss: () -> Void
    var onCheckForUpdates: (() -> Void)?
    
    // Use AppearanceManager to sync with Settings theme
    private var effectiveColorScheme: ColorScheme {
        switch appearanceManager.currentMode {
        case .system: return systemColorScheme
        case .dark: return .dark
        case .light: return .light
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            ZKMenuDivider(colorScheme: effectiveColorScheme)
            
            // Main Toggle Section
            mainToggleSection
                .padding(.vertical, 8)
            
            ZKMenuDivider(colorScheme: effectiveColorScheme)
            
            // Quick Stats Section
            quickStatsSection
                .padding(.vertical, 8)
            
            ZKMenuDivider(colorScheme: effectiveColorScheme)
            
            // Settings Section (Input Method, Code Table)
            settingsSection
                .padding(.vertical, 6)
            
            ZKMenuDivider(colorScheme: effectiveColorScheme)
            
            // Tools Section
            toolsSection
                .padding(.vertical, 6)
            
            ZKMenuDivider(colorScheme: effectiveColorScheme)
            
            // Footer Actions
            footerSection
                .padding(.vertical, 6)
        }
        .frame(width: 400)
        .background(menuBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AdaptiveColors.glassBorder(for: effectiveColorScheme), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(effectiveColorScheme == .dark ? 0.4 : 0.15), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Background
    
    private var menuBackground: some View {
        // Use same background as settings content area for consistency
        // Dark mode: gradient from #16213e to #1a1a2e (purple-ish)
        // Light mode: gradient from white to #F5F5F7
        AdaptiveColors.contentBackgroundGradient(for: effectiveColorScheme)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 14) {
            // Logo with flag badge
            ZStack(alignment: .topTrailing) {
                Image("ZendyKeyLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Flag badge
                Text(viewModel.isVietnameseEnabled ? "🇻🇳" : "🇬🇧")
                    .font(.system(size: 16))
                    .offset(x: 10, y: -8)
            }
            .frame(width: 52, height: 44)
            
            // App info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("ZendyKey")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AdaptiveColors.textPrimary(for: effectiveColorScheme))
                    
                    Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AdaptiveColors.textTertiary(for: effectiveColorScheme))
                }
                
                // Status info - single line with truncation
                if viewModel.isVietnameseEnabled {
                    Text("\(viewModel.currentInputMethod.displayName) · \(viewModel.currentCodeTable.displayName)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AdaptiveColors.textSecondary(for: effectiveColorScheme))
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Text("Đã tắt gõ tiếng Việt")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AdaptiveColors.textSecondary(for: effectiveColorScheme))
                }
            }
            
            Spacer()
            
            // Settings button - styled like sidebar menu items
            Button(action: {
                viewModel.openPreferences()
                onDismiss()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        hoveredItem == "settings"
                            ? ZKColors.accentGradient
                            : LinearGradient(colors: [AdaptiveColors.textSecondary(for: effectiveColorScheme)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(hoveredItem == "settings" 
                                ? AdaptiveColors.glassHighlight(for: effectiveColorScheme)
                                : Color.clear)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                    .scaleEffect(hoveredItem == "settings" ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: hoveredItem == "settings")
            }
            .buttonStyle(.plain)
            .focusable(false)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    hoveredItem = hovering ? "settings" : nil
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Main Toggle Section
    
    private var mainToggleSection: some View {
        VStack(spacing: 0) {
            Button(action: { 
                withAnimation(ZKAnimations.spring) {
                    viewModel.toggleVietnamese()
                }
            }) {
                HStack(alignment: .center, spacing: 14) {
                    // VI/EN Icon Badge - same style as settings
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(ZKColors.accent.opacity(0.12))
                            .frame(width: 36, height: 36)
                        
                        Text(viewModel.isVietnameseEnabled ? "VI" : "EN")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(ZKColors.accentGradient)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Gõ tiếng Việt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AdaptiveColors.textPrimary(for: effectiveColorScheme))
                            .lineLimit(1)
                        
                        Text("Nhấn \(ZKSharedSettings.shared.loadPreferences().toggleHotkey.displayString) để bật tắt")
                            .font(.system(size: 12))
                            .foregroundColor(AdaptiveColors.textSecondary(for: effectiveColorScheme))
                            .lineLimit(1)
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
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(hoveredItem == "toggle" 
                            ? AdaptiveColors.glassHighlight(for: effectiveColorScheme)
                            : Color.clear)
                )
                .scaleEffect(hoveredItem == "toggle" ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: hoveredItem == "toggle")
            }
            .buttonStyle(.plain)
            .focusable(false)
            .onHover { hovering in
                withAnimation(ZKAnimations.springFast) {
                    hoveredItem = hovering ? "toggle" : nil
                }
            }
            .padding(.horizontal, 10)
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(spacing: 6) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(ZKColors.accentGradient)
                
                Text("Tốc độ gõ phím hôm nay")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AdaptiveColors.textSecondary(for: effectiveColorScheme))
                
                Spacer()
                
                Button(action: {
                    viewModel.openStatistics()
                    onDismiss()
                }) {
                    Text("Xem chi tiết")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(hoveredItem == "stats" 
                            ? ZKColors.accent 
                            : AdaptiveColors.textPrimary(for: effectiveColorScheme))
                        .scaleEffect(hoveredItem == "stats" ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: hoveredItem == "stats")
                }
                .buttonStyle(.plain)
                .focusable(false)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hoveredItem = hovering ? "stats" : nil
                    }
                }
            }
            .padding(.horizontal, 14)
            
            // Stats display
            HStack(spacing: 0) {
                // WPM (today's average)
                VStack(spacing: 2) {
                    Text("\(Int(ZKStatisticsManager.shared.todayAverageWPM))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(ZKColors.successGradient)
                    
                    Text("từ/phút")
                        .font(.system(size: 9))
                        .foregroundColor(AdaptiveColors.textTertiary(for: effectiveColorScheme))
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(AdaptiveColors.glassBorder(for: effectiveColorScheme))
                    .frame(width: 1, height: 28)
                
                // CPM (today's average)
                VStack(spacing: 2) {
                    Text("\(Int(ZKStatisticsManager.shared.todayAverageCPM))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(ZKColors.accentGradient)
                    
                    Text("ký tự/phút")
                        .font(.system(size: 9))
                        .foregroundColor(AdaptiveColors.textTertiary(for: effectiveColorScheme))
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(AdaptiveColors.glassBorder(for: effectiveColorScheme))
                    .frame(width: 1, height: 28)
                
                // Today keystrokes
                VStack(spacing: 2) {
                    Text(formatCompactNumber(ZKStatisticsManager.shared.todayKeystrokes))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AdaptiveColors.textPrimary(for: effectiveColorScheme))
                    
                    Text("phím hôm nay")
                        .font(.system(size: 9))
                        .foregroundColor(AdaptiveColors.textTertiary(for: effectiveColorScheme))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: effectiveColorScheme == .dark
                                ? [Color.green.opacity(0.08), Color.blue.opacity(0.05)]
                                : [Color.green.opacity(0.05), Color.blue.opacity(0.03)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .padding(.horizontal, 10)
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
        VStack(spacing: 2) {
            // Input Method
            ZKMenuItemWithSubmenu(
                icon: "keyboard",
                title: "Kiểu gõ",
                hotkey: ZKSharedSettings.shared.loadPreferences().inputMethodHotkey?.displayString,
                value: viewModel.currentInputMethod.displayName,
                isExpanded: expandedSubmenu == "inputMethod",
                isHovered: hoveredItem == "inputMethod",
                colorScheme: effectiveColorScheme,
                onToggle: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        expandedSubmenu = expandedSubmenu == "inputMethod" ? nil : "inputMethod"
                    }
                }
            ) {
                // Submenu content
                ForEach(InputMethod.orderedCases, id: \.self) { method in
                    ZKSubmenuItem(
                        title: method.displayName,
                        isSelected: method == viewModel.currentInputMethod,
                        isHovered: hoveredItem == "im_\(method.rawValue)",
                        colorScheme: effectiveColorScheme
                    ) {
                        viewModel.selectInputMethod(method)
                    }
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredItem = hovering ? "im_\(method.rawValue)" : nil
                        }
                    }
                }
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    if expandedSubmenu != "inputMethod" {
                        hoveredItem = hovering ? "inputMethod" : nil
                    }
                }
            }
            
            // Code Table
            ZKMenuItemWithSubmenu(
                icon: "doc.text",
                title: "Bảng mã",
                hotkey: ZKSharedSettings.shared.loadPreferences().codeTableHotkey?.displayString,
                value: viewModel.currentCodeTable.displayName,
                isExpanded: expandedSubmenu == "codeTable",
                isHovered: hoveredItem == "codeTable",
                colorScheme: effectiveColorScheme,
                onToggle: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        expandedSubmenu = expandedSubmenu == "codeTable" ? nil : "codeTable"
                    }
                }
            ) {
                ForEach(CodeTable.allCases, id: \.self) { table in
                    ZKSubmenuItem(
                        title: table.displayName,
                        isSelected: table == viewModel.currentCodeTable,
                        isHovered: hoveredItem == "ct_\(table.rawValue)",
                        colorScheme: effectiveColorScheme
                    ) {
                        viewModel.selectCodeTable(table)
                    }
                    .onHover { hovering in
                        withAnimation(ZKAnimations.springFast) {
                            hoveredItem = hovering ? "ct_\(table.rawValue)" : nil
                        }
                    }
                }
            }
            .onHover { hovering in
                withAnimation(ZKAnimations.springFast) {
                    if expandedSubmenu != "codeTable" {
                        hoveredItem = hovering ? "codeTable" : nil
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Tools Section
    
    private var toolsSection: some View {
        VStack(spacing: 2) {
            ZKMenuItem(
                icon: "text.quote",
                title: "Quản lý Macro",
                isHovered: hoveredItem == "macro",
                colorScheme: effectiveColorScheme
            ) {
                viewModel.openMacroManagement()
                onDismiss()
            }
            .onHover { hovering in
                withAnimation(ZKAnimations.springFast) {
                    hoveredItem = hovering ? "macro" : nil
                }
            }
            
            ZKMenuItem(
                icon: "arrow.triangle.2.circlepath",
                title: "Công cụ chuyển đổi",
                isHovered: hoveredItem == "convert",
                colorScheme: effectiveColorScheme
            ) {
                viewModel.openZKConvertTool()
                onDismiss()
            }
            .onHover { hovering in
                withAnimation(ZKAnimations.springFast) {
                    hoveredItem = hovering ? "convert" : nil
                }
            }
            

        }
        .padding(.horizontal, 8)
    }
    
    private func getUpdateTitle() -> String {
        switch viewModel.updateStatus {
        case .idle: return "Kiểm tra cập nhật..."
        case .checking: return "Đang kiểm tra..."
        case .upToDate: return "✓ Đã cập nhật mới nhất"
        case .available(let version): return "⬆ Có bản cập nhật v\(version)"
        case .downloading(let progress): return "⬇ Đang tải... \(Int(progress * 100))%"
        case .error: return "⚠️ Lỗi - thử lại"
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 2) {
            ZKMenuItem(
                icon: "arrow.clockwise",
                title: getUpdateTitle(),
                isHovered: hoveredItem == "update",
                colorScheme: effectiveColorScheme
            ) {
                onCheckForUpdates?()
            }
            .onHover { hovering in
                withAnimation(ZKAnimations.springFast) {
                    hoveredItem = hovering ? "update" : nil
                }
            }
            
            ZKMenuItem(
                icon: "power",
                title: "Thoát ZendyKey",
                shortcut: "⌘Q",
                isDestructive: true,
                isHovered: hoveredItem == "quit",
                colorScheme: effectiveColorScheme
            ) {
                viewModel.quit()
            }
            .onHover { hovering in
                withAnimation(ZKAnimations.springFast) {
                    hoveredItem = hovering ? "quit" : nil
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Menu Divider

struct ZKMenuDivider: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        Rectangle()
            .fill(AdaptiveColors.glassBorder(for: colorScheme))
            .frame(height: 1)
            .padding(.horizontal, 12)
    }
}

// MARK: - Menu Item

struct ZKMenuItem: View {
    let icon: String
    let title: String
    var shortcut: String? = nil
    var isDestructive: Bool = false
    let isHovered: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with gradient
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        isDestructive 
                            ? LinearGradient(colors: [.red], startPoint: .leading, endPoint: .trailing)
                            : (isHovered ? ZKColors.accentGradient : LinearGradient(colors: [AdaptiveColors.textSecondary(for: colorScheme)], startPoint: .leading, endPoint: .trailing))
                    )
                    .frame(width: 20)
                
                Text(title)
                    .font(ZKTypography.body)
                    .foregroundColor(isDestructive ? .red : AdaptiveColors.textPrimary(for: colorScheme))
                
                Spacer()
                
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AdaptiveColors.textTertiary(for: colorScheme))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered 
                        ? (isDestructive ? Color.red.opacity(0.1) : AdaptiveColors.glassHighlight(for: colorScheme))
                        : Color.clear)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

// MARK: - Menu Item with Submenu

struct ZKMenuItemWithSubmenu<Content: View>: View {
    let icon: String
    let title: String
    let hotkey: String?  // Optional hotkey display
    let value: String
    let isExpanded: Bool
    let isHovered: Bool
    let colorScheme: ColorScheme
    let onToggle: () -> Void
    @ViewBuilder let content: Content
    
    init(icon: String, title: String, hotkey: String? = nil, value: String, isExpanded: Bool, isHovered: Bool, colorScheme: ColorScheme, onToggle: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.hotkey = hotkey
        self.value = value
        self.isExpanded = isExpanded
        self.isHovered = isHovered
        self.colorScheme = colorScheme
        self.onToggle = onToggle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Icon - white by default, gradient when hovered or expanded
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            (isHovered || isExpanded)
                                ? AnyShapeStyle(ZKColors.accentGradient)
                                : AnyShapeStyle(AdaptiveColors.textSecondary(for: colorScheme))
                        )
                        .frame(width: 20)
                    
                    // Title with optional hotkey
                    HStack(spacing: 4) {
                        Text(title)
                            .font(ZKTypography.body)
                            .foregroundColor(AdaptiveColors.textPrimary(for: colorScheme))
                        
                        if let hotkey = hotkey {
                            Text("(\(hotkey))")
                                .font(ZKTypography.caption)
                                .foregroundColor(AdaptiveColors.textSecondary(for: colorScheme))
                        }
                    }
                    
                    Spacer()
                    
                    Text(value)
                        .font(ZKTypography.caption)
                        .foregroundColor(AdaptiveColors.textSecondary(for: colorScheme))
                    
                    // Chevron with rotation animation - fixed in place
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AdaptiveColors.textTertiary(for: colorScheme))
                        .frame(width: 12, height: 12) // Fixed size to prevent layout shift
                        .rotationEffect(.degrees(isExpanded ? 90 : 0), anchor: .center)
                        .animation(.easeInOut(duration: 0.15), value: isExpanded)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle()) // Make entire row clickable
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((isHovered || isExpanded) ? AdaptiveColors.glassHighlight(for: colorScheme) : Color.clear)
                        .animation(.easeInOut(duration: 0.15), value: isHovered)
                        .animation(.easeInOut(duration: 0.15), value: isExpanded)
                )
                // No scaleEffect to prevent row from moving
            }
            .buttonStyle(.plain)
            .focusable(false)
            
            // Submenu content - fade in place (no slide from above)
            if isExpanded {
                VStack(spacing: 2) {
                    content
                }
                .padding(.leading, 32)
                .padding(.top, 4)
            }
        }
        // No container animation to prevent jitter
    }
}

// MARK: - Submenu Item

struct ZKSubmenuItem: View {
    let title: String
    let isSelected: Bool
    let isHovered: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Selection indicator
                Circle()
                    .fill(isSelected ? ZKColors.accentGradient : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.clear : AdaptiveColors.glassBorder(for: colorScheme), lineWidth: 1)
                    )
                
                Text(title)
                    .font(ZKTypography.body)
                    .foregroundColor(isSelected ? ZKColors.accent : AdaptiveColors.textPrimary(for: colorScheme))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(ZKColors.accentGradient)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? AdaptiveColors.glassHighlight(for: colorScheme) : Color.clear)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Menu Popover Controller

class ZKMenuBarPopoverController: NSObject {
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private weak var viewModel: ZKStatusBarViewModel?
    var onCheckForUpdates: (() -> Void)?
    
    init(viewModel: ZKStatusBarViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    func showPopover(from statusBarButton: NSStatusBarButton) {
        guard let viewModel = viewModel else { return }
        
        // Create popover if needed
        if popover == nil {
            popover = NSPopover()
            popover?.behavior = .transient
            // Enable animation for smooth slide in/out
            popover?.animates = true
        }
        
        // Create SwiftUI content
        let menuView = ZKModernMenuView(
            viewModel: viewModel,
            onDismiss: { [weak self] in
                self?.dismissPopover()
            },
            onCheckForUpdates: onCheckForUpdates
        )
        
        popover?.contentViewController = NSHostingController(rootView: menuView)
        
        // Show popover
        popover?.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .minY)
        
        // Set window level higher than Settings window (.floating)
        // This ensures popover appears above Settings when both are visible
        if let popoverWindow = popover?.contentViewController?.view.window {
            popoverWindow.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        }
        
        // Setup event monitor to dismiss on outside click
        setupEventMonitor()
    }
    
    func dismissPopover() {
        popover?.performClose(nil)
        removeEventMonitor()
    }
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismissPopover()
        }
    }
    
    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    var isShown: Bool {
        popover?.isShown ?? false
    }
}

// MARK: - Preview

#if DEBUG
struct ZKModernMenuView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZKModernMenuView(
                viewModel: ZKStatusBarViewModel(keyboardHandler: nil, eventTapManager: nil),
                onDismiss: {}
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
            
            ZKModernMenuView(
                viewModel: ZKStatusBarViewModel(keyboardHandler: nil, eventTapManager: nil),
                onDismiss: {}
            )
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
        }
        .padding()
    }
}
#endif
