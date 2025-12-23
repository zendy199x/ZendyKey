//
//  ZKSettingsView.swift
//  ZendyKey
//
//  Unified Settings View with Apple-style sidebar navigation
//  Supports macOS 26 Tahoe Liquid Glass design
//

import SwiftUI

// MARK: - Settings Section

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "Cơ bản"
    case quickTyping = "Gõ nhanh"
    case advanced = "Nâng cao"
    case inputSources = "Input Sources"
    case excludedApps = "Loại trừ"
    case macro = "Macro"
    case convertTool = "Chuyển đổi"
    case appearance = "Hệ thống"
    case about = "Giới thiệu"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .quickTyping: return "keyboard"
        case .advanced: return "slider.horizontal.3"
        case .inputSources: return "globe"
        case .excludedApps: return "app.badge.fill"
        case .macro: return "text.badge.plus"
        case .convertTool: return "arrow.left.arrow.right"
        case .appearance: return "gearshape.2"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Main Settings View

@available(macOS 13.0, *)
struct ZKSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = ZKPreferencesViewModel()
    @State private var selectedSection: SettingsSection

    var onSave: ((Preferences) -> Void)?
    var onClose: (() -> Void)?

    init(selectedSection: SettingsSection = .general, onSave: ((Preferences) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self._selectedSection = State(initialValue: selectedSection)
        self.onSave = onSave
        self.onClose = onClose
    }

    var body: some View {
        HStack(spacing: 0) {
            // Modern Glassmorphism Sidebar
            VStack(alignment: .leading, spacing: 8) {
                // App Header
                HStack(spacing: 12) {
                    Image("ZendyKeyLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ZendyKey")
                            .font(ZKTypography.headline)
                            .foregroundColor(ZKColors.textPrimary)
                        Text("Cài đặt")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textTertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .background(ZKColors.glassBorder)
                    .padding(.horizontal, 16)
                
                // Sidebar Items
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(SettingsSection.allCases) { section in
                            ZKSidebarItem(
                                title: section.rawValue,
                                icon: section.icon,
                                isSelected: selectedSection == section,
                                action: {
                                    withAnimation(ZKAnimations.spring) {
                                        selectedSection = section
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                
                Spacer()
                
                // Update Badge - Version and update status
                ZKUpdateBadgeView(
                    status: .idle,
                    onCheck: {
                        ZKAppDelegate.shared?.checkForUpdatesFromUI()
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(width: 200)
            .background(AdaptiveColors.sidebarBackgroundView(for: colorScheme))
            
            // Separator
            Rectangle()
                .fill(ZKColors.glassBorder)
                .frame(width: 1)
            
            // Content Area
            ZStack {
                // Background gradient (adaptive)
                AdaptiveColors.contentBackgroundGradient(for: colorScheme)
                .ignoresSafeArea()
                
                // Content
                Group {
                    switch selectedSection {
                    case .general:
                        GeneralSettingsSection(viewModel: viewModel)
                    case .quickTyping:
                        QuickTypingSettingsSection(viewModel: viewModel)
                    case .advanced:
                        AdvancedSettingsSection(viewModel: viewModel)
                    case .inputSources:
                        InputSourcesSettingsSection()
                    case .excludedApps:
                        ExcludedAppsSettingsSection(viewModel: viewModel)
                    case .macro:
                        MacroSettingsSection(prefsViewModel: viewModel)
                    case .convertTool:
                        ZKConvertToolSection()
                    case .appearance:
                        AppearanceSettingsSection(viewModel: viewModel)
                    case .about:
                        AboutSettingsSection()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .frame(width: 850, height: 600)
        .background(AdaptiveColors.surfaceBackground(for: colorScheme))
        .onReceive(viewModel.objectWillChange) { _ in
            // Auto-save when any preference changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.save()
                onSave?(viewModel.preferences)
            }
        }
    }
}


// MARK: - General Settings Section

struct GeneralSettingsSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hotkey
                SettingsGroup(title: "Phím tắt") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Bật/tắt tiếng Việt:")
                            Spacer()
                            ZKHotkeyRecorderView(hotkey: $viewModel.preferences.toggleHotkey)
                                .frame(width: 150)
                        }
                        
                        Toggle("Phát âm thanh khi bật/tắt", isOn: $viewModel.preferences.beepOnToggle)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Hoàn tác gõ tiếng Việt bằng phím Esc", isOn: $viewModel.preferences.undoTypingEnabled)
                            
                            Text("Nhấn Esc ngay sau khi gõ để hoàn tác việc bỏ dấu (ví dụ: \"tiếng\" → \"tieesng\")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Input Method
                SettingsGroup(title: "Kiểu gõ") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(InputMethod.allCases, id: \.self) { method in
                            SettingsRadioButton(
                                title: method.displayName,
                                isSelected: viewModel.preferences.inputMethod == method
                            ) {
                                viewModel.preferences.inputMethod = method
                            }
                        }
                    }
                }
                
                // Code Table
                SettingsGroup(title: "Bảng mã") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(CodeTable.allCases, id: \.self) { table in
                            SettingsRadioButton(
                                title: table.displayName,
                                isSelected: viewModel.preferences.codeTable == table
                            ) {
                                viewModel.preferences.codeTable = table
                            }
                        }
                    }
                }
                
                // Basic Options
                SettingsGroup(title: "Tùy chọn") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Kiểu gõ hiện đại (oà/uý)", isOn: $viewModel.preferences.modernStyle)
                        Toggle("Kiểm tra chính tả", isOn: $viewModel.preferences.spellCheckEnabled)
                        Toggle("Sửa lỗi tự động hoàn thành (áp dụng cho Chrome, Terminal...)", isOn: $viewModel.preferences.fixAutocomplete)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Tự động khôi phục tiếng Anh", isOn: $viewModel.preferences.autoRestoreEnglishEnabled)
                            
                            Text("Tự động chuyển về tiếng Anh khi phát hiện từ như 'text', 'window', 'file'...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Hiển thị chỉ báo trên màn hình", isOn: $viewModel.preferences.showOnScreenIndicator)
                            
                            Text("Hiển thị icon V/E khi chuyển ngôn ngữ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

// MARK: - Quick Typing Settings Section

struct QuickTypingSettingsSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsGroup(title: "Quick Telex") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Bật Quick Telex", isOn: $viewModel.preferences.quickTelexEnabled)
                        
                        Text("cc→ch, gg→gi, kk→kh, nn→ng, pp→ph, qq→qu, tt→th")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                SettingsGroup(title: "Quick Consonant - Đầu từ") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Bật Quick Start Consonant", isOn: $viewModel.preferences.quickStartConsonantEnabled)
                        
                        Text("f→ph, j→gi, w→qu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                SettingsGroup(title: "Quick Consonant - Cuối từ") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Bật Quick End Consonant", isOn: $viewModel.preferences.quickEndConsonantEnabled)
                        
                        Text("g→ng, h→nh, k→ch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

// MARK: - Advanced Settings Section

struct AdvancedSettingsSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsGroup(title: "Chính tả & Viết hoa") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Khôi phục nếu sai chính tả", isOn: $viewModel.preferences.restoreIfWrongSpelling)
                        Toggle("Tự động viết hoa chữ đầu câu", isOn: $viewModel.preferences.upperCaseFirstChar)
                        Toggle("Cho phép phụ âm Z, F, W, J", isOn: $viewModel.preferences.allowConsonantZFWJ)
                    }
                }
                
                SettingsGroup(title: "Đặt dấu") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Đặt dấu tự do (Free Mark)", isOn: $viewModel.preferences.freeMarkEnabled)
                        
                        Text("Cho phép đặt dấu ở bất kỳ vị trí nào trong từ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("Đặt thanh tự do (Free Tone)", isOn: $viewModel.preferences.freeToneEnabled)
                        
                        Text("Bỏ qua kiểm tra chính tả khi đặt thanh")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                SettingsGroup(title: "Telex") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Bỏ qua w→ư", isOn: $viewModel.preferences.skipWShortcut)
                        
                        Text("Giữ 'w' là 'w' thay vì chuyển thành 'ư' ở đầu từ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                SettingsGroup(title: "Ghi nhớ ứng dụng") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Nhớ ngôn ngữ theo ứng dụng", isOn: $viewModel.preferences.perAppModeEnabled)
                        
                        Text("Tự động nhớ Việt/Anh cho từng ứng dụng")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                SettingsGroup(title: "Tạm tắt") {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Tạm tắt chính tả bằng phím Ctrl", isOn: $viewModel.preferences.tempOffSpellingEnabled)
                            
                            Text("Giữ Ctrl khi gõ để tạm thời tắt kiểm tra chính tả")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Tạm tắt gõ tiếng Việt bằng phím Option", isOn: $viewModel.preferences.tempOffEngineEnabled)
                            
                            Text("Giữ Option (⌥) khi gõ để tạm thời tắt bộ gõ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                SettingsGroup(title: "Smart Switch") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Main Smart Switch toggle
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Nhớ ngôn ngữ theo ứng dụng", isOn: $viewModel.preferences.smartSwitchEnabled)

                            Text("Tự động chuyển ngôn ngữ khi chuyển app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Overlay app detection (sub-option, only shown when Smart Switch is enabled)
                        if viewModel.preferences.smartSwitchEnabled {
                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Hỗ trợ phát hiện Spotlight/Raycast/Alfred", isOn: $viewModel.preferences.detectOverlayApps)

                                // Info message
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Tránh ghi đè ngôn ngữ của app bên dưới khi bạn toggle trong Spotlight/Raycast")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.05))
                                    .cornerRadius(6)
                                }
                            }
                            .padding(.leading, 20)  // Indent sub-option
                        }
                    }
                }
                
                // Window Title Rules
                SettingsGroup(title: "Quy tắc theo Window Title") {
                    if #available(macOS 13.0, *) {
                        ZKWindowTitleRulesView()
                    } else {
                        Text("Tính năng này yêu cầu macOS 13.0 trở lên")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // PHTV Feature: Compatibility Settings
                SettingsGroup(title: "Tương thích") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Sửa lỗi Chromium (Chrome/Arc/Edge)", isOn: $viewModel.preferences.fixChromiumBrowser)
                            
                            Text("Tự động sửa lỗi dính chữ trong thanh địa chỉ của Chrome, Arc, Edge")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Tương thích layout bàn phím", isOn: $viewModel.preferences.performLayoutCompat)
                            
                            Text("Bật nếu bạn dùng layout bàn phím khác QWERTY")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Gửi từng phím (Send Key Step By Step)", isOn: $viewModel.preferences.sendKeyStepByStep)
                            
                            Text("Bật nếu một số ứng dụng không nhận được phím khi gõ nhanh")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // PHTV Feature: Per-App SendKeyStepByStep  
                SettingsGroup(title: "Ứng dụng cần gửi từng phím") {
                    SendKeyStepByStepAppsSettingsSection(viewModel: viewModel)
                }
                
                // PHTV Feature: Pause Key Configuration
                ZKPauseKeyConfigSection(viewModel: viewModel)
                
                // PHTV Feature: Restore Key Configuration  
                ZKRestoreKeyConfigSection(viewModel: viewModel)
                
                // IMKit Mode (Experimental) - Placed before Debug
                SettingsGroup(title: "Input Method Kit (Thử nghiệm)") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Bật IMKit Mode", isOn: $viewModel.preferences.imkitEnabled)

                            Text("Sử dụng Input Method Kit thay vì CGEvent injection. Giúp gõ mượt hơn trong Terminal app và IDE Terminal.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if viewModel.preferences.imkitEnabled {
                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Hiển thị gạch chân khi gõ (Khuyến nghị)", isOn: $viewModel.preferences.imkitUseMarkedText)
                                    .padding(.leading, 20)

                                Text(viewModel.preferences.imkitUseMarkedText ?
                                    "✓ Chuẩn IMKit - Hiển thị gạch chân khi đang gõ. Ổn định và tương thích tốt với mọi ứng dụng." :
                                    "⚠️ Direct Mode - Không có gạch chân nhưng có thể gặp lỗi thêm dấu/double ký tự trong một số trường hợp trên các app khác nhau. Nếu gặp lỗi như vậy hãy bật tính năng này lên và thử lại.")
                                    .font(.caption)
                                    .foregroundColor(viewModel.preferences.imkitUseMarkedText ? .secondary : .orange)
                                    .padding(.leading, 20)
                            }
                            
                            Divider()
                            
                            // Install ZKIMMain button
                            HStack {
                                Text("ZKIMMain Input Method:")
                                    .font(.caption)
                                Spacer()
                                Button("Cài đặt ZKIMMain...") {
                                    ZKIMKitHelper.installZKIMMain()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            Text("Sau khi cài đặt, vào System Settings → Keyboard → Input Sources để thêm ZendyKey Vietnamese")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            // Quick switch hotkey
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Phím tắt chuyển nhanh sang ZendyKey:")
                                        .font(.caption)
                                    Spacer()
                                    // Use custom binding for optional hotkey
                                    ZKHotkeyRecorderView(hotkey: Binding(
                                        get: { viewModel.preferences.switchToZendyKeyHotkey ?? Hotkey(keyCode: 0, modifiers: []) },
                                        set: { newValue in
                                            // Set to nil if empty, otherwise save the hotkey
                                            if newValue.keyCode == 0 && newValue.modifiers.isEmpty {
                                                viewModel.preferences.switchToZendyKeyHotkey = nil
                                            } else {
                                                viewModel.preferences.switchToZendyKeyHotkey = newValue
                                            }
                                        }
                                    ))
                                        .frame(width: 150)
                                }
                                
                                Text("Phím tắt này sẽ toggle giữa ZendyKey và ABC. Nếu đang dùng ZendyKey → chuyển sang ABC (hoặc bộ gõ tiếng Anh khác), ngược lại → ZendyKey")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                // Quick switch button
                                HStack {
                                    Button("Chuyển sang ZendyKey ngay") {
                                        ZKInputSourceSwitcher.shared.switchToZendyKey()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                
                // Debug - At the very end
                SettingsGroup(title: "Debug") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Bật chế độ Debug", isOn: $viewModel.preferences.debugModeEnabled)
                        
                        Text("Hiển thị cửa sổ debug để theo dõi hoạt động của bộ gõ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

// MARK: - Appearance Settings Section

struct AppearanceSettingsSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel
    @State private var hasAccessibilityPermission = AXIsProcessTrusted()
    @State private var showResetConfirmation = false
    
    private let permissionCheckTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Accessibility Permission
                SettingsGroup(title: "Quyền truy cập") {
                    HStack {
                        Image(systemName: hasAccessibilityPermission ? "checkmark.shield.fill" : "xmark.shield.fill")
                            .foregroundColor(hasAccessibilityPermission ? .green : .red)
                            .font(.system(size: 18))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(hasAccessibilityPermission ? "Đã cấp quyền Accessibility" : "Chưa cấp quyền Accessibility")
                                .font(.subheadline)
                                .foregroundColor(hasAccessibilityPermission ? .primary : .red)
                            
                            Text("ZendyKey cần quyền này để nhận phím từ bàn phím")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !hasAccessibilityPermission {
                            Button("Mở Cài đặt") {
                                openAccessibilitySettings()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                
                // Theme selection (Dark/Light/System)
                SettingsGroup(title: "Giao diện") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chế độ màu:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        AppearancePickerView()
                            .padding(.top, 4)
                        
                        Text("Chọn chế độ sáng, tối hoặc tự động theo hệ thống")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Sound Settings
                SettingsGroup(title: "Âm thanh") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Phát âm thanh khi chuyển ngôn ngữ", isOn: $viewModel.preferences.beepOnToggle)
                        
                        Text("Phát âm thanh khi bật/tắt tiếng Việt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Menu Bar Icon Settings (PHTV Feature)
                SettingsGroup(title: "Icon thanh Menu") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Icon size slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Kích thước icon:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(viewModel.preferences.menuBarIconSize)) px")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(ZKColors.accent.opacity(0.15))
                                    )
                            }
                            
                            Slider(value: $viewModel.preferences.menuBarIconSize, in: 12.0...20.0, step: 1.0)
                            
                            Text("Điều chỉnh kích thước icon trên thanh menu (12-20 pixels)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Vietnamese menubar icon toggle
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Hiển thị icon chữ V khi ở chế độ tiếng Việt", isOn: $viewModel.preferences.useVietnameseMenubarIcon)
                            
                            Text("Khi bật, icon sẽ chuyển thành chữ V khi đang ở chế độ tiếng Việt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                SettingsGroup(title: "Dock") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Hiển thị biểu tượng trên thanh Dock", isOn: $viewModel.preferences.showDockIcon)
                        
                        Text("Khi bật, ZendyKey sẽ hiển thị icon trên Dock như các ứng dụng thông thường")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                SettingsGroup(title: "Khởi động") {
                    Toggle("Khởi động cùng hệ thống", isOn: $viewModel.preferences.startAtLogin)
                }
                
                // Beep Volume Slider (PHTV Feature)
                if viewModel.preferences.beepOnToggle {
                    SettingsGroup(title: "Âm lượng") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Âm lượng:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(viewModel.preferences.beepVolume * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $viewModel.preferences.beepVolume, in: 0.0...1.0, step: 0.1)
                            
                            Text("Điều chỉnh âm lượng khi chuyển ngôn ngữ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Reset to Defaults (PHTV Feature)
                SettingsGroup(title: "Khôi phục mặc định") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Đặt lại tất cả cài đặt về mặc định. Dữ liệu macro sẽ được giữ nguyên.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showResetConfirmation = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Khôi phục mặc định")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .onReceive(permissionCheckTimer) { _ in
            hasAccessibilityPermission = AXIsProcessTrusted()
        }
        .alert("Khôi phục mặc định?", isPresented: $showResetConfirmation) {
            Button("Hủy", role: .cancel) { }
            Button("Khôi phục", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("Tất cả cài đặt sẽ được đặt lại về mặc định. Dữ liệu macro sẽ được giữ nguyên. Hành động này không thể hoàn tác.")
        }
    }
    
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func resetToDefaults() {
        // Create a new default preferences object but preserve macros
        var defaultPrefs = Preferences()
        // Keep the current macros
        defaultPrefs.excludedApps = []  // Clear excluded apps
        defaultPrefs.sendKeyStepByStepApps = []  // Clear step-by-step apps
        
        // Apply default preferences
        viewModel.preferences = defaultPrefs
        viewModel.save()
    }
}

// MARK: - About Settings Section

struct AboutSettingsSection: View {
    @State private var showDonationDialog = false
    @State private var versionBounce = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // App Logo with Glass Effect (macOS 26+ style)
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ZKColors.accent.opacity(0.15),
                                        ZKColors.accent.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        if let logo = NSImage(named: "ZendyKeyLogo") {
                            Image(nsImage: logo)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                        } else {
                            Image(systemName: "keyboard.badge.ellipsis")
                                .font(.system(size: 40))
                                .foregroundColor(ZKColors.accent)
                        }
                    }
                    
                    // App Name
                    VStack(spacing: 6) {
                        Text("ZendyKey")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(ZKColors.textPrimary)
                        
                        Text("Vietnamese Input Method for macOS")
                            .font(ZKTypography.body)
                            .foregroundColor(ZKColors.textSecondary)
                    }
                    
                    // Version Badge with animation
                    HStack(spacing: 8) {
                        Text("Phiên bản")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textTertiary)
                        
                        Text("v\(ZKAppVersion.current)")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(ZKColors.accent.opacity(0.15))
                            )
                            .foregroundColor(ZKColors.accent)
                            .scaleEffect(versionBounce ? 1.05 : 1.0)
                    }
                }
                .padding(.top, 20)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                        versionBounce = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            versionBounce = false
                        }
                    }
                }
                
                Divider()
                    .padding(.horizontal, 60)
                
                // Developer Info Cards
                VStack(spacing: 12) {
                    AboutInfoCard(icon: "person.circle.fill", title: "Phát triển bởi", value: "Zendy199x")
                    AboutInfoCard(icon: "swift", title: "Công nghệ", value: "Swift & SwiftUI")
                    AboutInfoCard(icon: "shield.checkered", title: "Quyền riêng tư", value: "Offline, không thu thập dữ liệu")
                }
                .padding(.horizontal, 20)
                
                Divider()
                    .padding(.horizontal, 60)
                
                // Donation Section
                VStack(spacing: 12) {
                    Text("Ủng hộ phát triển")
                        .font(ZKTypography.headline)
                        .foregroundColor(ZKColors.textPrimary)
                    
                    Text("Nếu bạn thấy ZendyKey hữu ích, hãy ủng hộ để giúp phát triển thêm các tính năng mới")
                        .font(ZKTypography.caption)
                        .foregroundColor(ZKColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    Button(action: {
                        showDonationDialog = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "cup.and.saucer.fill")
                            Text("Buy me a coffee")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                    .padding(.horizontal, 60)

                // Update Check Section
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        Text("Kiểm tra phiên bản mới")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textSecondary)
                    }

                    Button("Kiểm tra cập nhật") {
                        if let settingsWindow = NSApp.keyWindow {
                            settingsWindow.level = .normal
                        }
                        
                        if let appDelegate = ZKAppDelegate.shared {
                            appDelegate.checkForUpdatesFromUI()
                        } else if let delegate = NSApplication.shared.delegate as? ZKAppDelegate {
                            delegate.checkForUpdatesFromUI()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ZKColors.glassBackground)
                )
                .padding(.horizontal, 30)
                
                Spacer(minLength: 20)
                
                // Copyright
                Text("Made with ❤️ in Vietnam • Inspired by Openkey & Unikey")
                    .font(.caption2)
                    .foregroundColor(ZKColors.textTertiary)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showDonationDialog) {
            ZKDonationView()
        }
    }
}

// MARK: - About Info Card Component (PHTV-inspired)

struct AboutInfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(ZKColors.accent)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(ZKColors.accent.opacity(0.12))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ZKTypography.caption)
                    .foregroundColor(ZKColors.textTertiary)
                Text(value)
                    .font(ZKTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(ZKColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? ZKColors.glassBackground : ZKColors.glassBackground.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? ZKColors.glassBorder : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(ZKAnimations.springFast, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}



// MARK: - Macro Settings Section (Embedded)

struct MacroSettingsSection: View {
    @StateObject private var viewModel = ZKMacroManagementViewModel()
    @ObservedObject var prefsViewModel: ZKPreferencesViewModel
    @State private var newMacroText: String = ""
    @State private var newMacroContent: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Settings Group
                SettingsGroup(title: "Cài đặt Macro") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Bật Macro", isOn: $prefsViewModel.preferences.macroEnabled)
                        
                        if prefsViewModel.preferences.macroEnabled {
                            Toggle("Dùng macro trong chế độ tiếng Anh", isOn: $prefsViewModel.preferences.macroInEnglishMode)
                                .padding(.leading, 20)
                            Toggle("Tự động viết hoa macro", isOn: $prefsViewModel.preferences.autoCapsMacro)
                                .padding(.leading, 20)
                        }
                    }
                }
                
                // Add new macro
                SettingsGroup(title: "Thêm macro mới") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .bottom, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Từ viết tắt")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("vd: btw", text: $newMacroText)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 120)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Nội dung thay thế")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("vd: by the way", text: $newMacroContent)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            Button("Thêm") {
                                addMacro()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(newMacroText.isEmpty || newMacroContent.isEmpty)
                        }
                        
                        if showError {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                // Macro list
                SettingsGroup(title: "Danh sách macro (\(viewModel.macros.count))") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: viewModel.importMacros) {
                                Label("Import", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: viewModel.exportMacros) {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            if !viewModel.macros.isEmpty {
                                Button(role: .destructive) {
                                    viewModel.clearAll()
                                } label: {
                                    Label("Xóa tất cả", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        
                        Divider()
                        
                        // Macro list
                        if viewModel.macros.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "text.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("Chưa có macro nào")
                                    .foregroundColor(.secondary)
                                Text("Thêm macro để tự động thay thế từ viết tắt")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.macros) { macro in
                                    MacroRowCompact(macro: macro) {
                                        viewModel.deleteMacro(macro)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .onAppear {
            viewModel.loadMacros()
        }
    }
    
    private func addMacro() {
        let trimmedText = newMacroText.trimmingCharacters(in: .whitespaces)
        let trimmedContent = newMacroContent.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedText.isEmpty && !trimmedContent.isEmpty else {
            showErrorMessage("Vui lòng nhập đầy đủ thông tin")
            return
        }
        
        guard trimmedText.count >= 2 else {
            showErrorMessage("Từ viết tắt phải có ít nhất 2 ký tự")
            return
        }
        
        if viewModel.addMacro(text: trimmedText, content: trimmedContent) {
            newMacroText = ""
            newMacroContent = ""
            showError = false
        } else {
            showErrorMessage("Macro '\(trimmedText)' đã tồn tại")
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }
}

struct MacroRowCompact: View {
    let macro: MacroItem
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Shortcut text
            Text(macro.text)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(4)
                .frame(minWidth: 80, alignment: .center)
            
            // Arrow
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .font(.system(size: 12, weight: .medium))
            
            // Content
            Text(macro.content)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(isHovered ? .red : .secondary)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.gray.opacity(0.03))
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}


// MARK: - Convert Tool Section (Embedded)

struct ZKConvertToolSection: View {
    @StateObject private var viewModel = ZKConvertToolViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Input text
                SettingsGroup(title: "Văn bản gốc") {
                    TextEditor(text: $viewModel.inputText)
                        .font(.body)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.2), width: 1)
                        .cornerRadius(4)
                }
                
                // Conversion options
                SettingsGroup(title: "Chuyển đổi chữ hoa/thường") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 20) {
                            Toggle("Viết hoa tất cả", isOn: $viewModel.toAllCaps)
                                .onChange(of: viewModel.toAllCaps) { newValue in
                                    if newValue {
                                        viewModel.toAllNonCaps = false
                                        viewModel.toCapsFirstLetter = false
                                        viewModel.toCapsEachWord = false
                                    }
                                }
                            
                            Toggle("Viết thường tất cả", isOn: $viewModel.toAllNonCaps)
                                .onChange(of: viewModel.toAllNonCaps) { newValue in
                                    if newValue {
                                        viewModel.toAllCaps = false
                                        viewModel.toCapsFirstLetter = false
                                        viewModel.toCapsEachWord = false
                                    }
                                }
                        }
                        
                        HStack(spacing: 20) {
                            Toggle("Viết hoa chữ đầu", isOn: $viewModel.toCapsFirstLetter)
                                .onChange(of: viewModel.toCapsFirstLetter) { newValue in
                                    if newValue {
                                        viewModel.toAllCaps = false
                                        viewModel.toAllNonCaps = false
                                        viewModel.toCapsEachWord = false
                                    }
                                }
                            
                            Toggle("Viết hoa mỗi từ", isOn: $viewModel.toCapsEachWord)
                                .onChange(of: viewModel.toCapsEachWord) { newValue in
                                    if newValue {
                                        viewModel.toAllCaps = false
                                        viewModel.toAllNonCaps = false
                                        viewModel.toCapsFirstLetter = false
                                    }
                                }
                        }
                    }
                }
                
                SettingsGroup(title: "Tùy chọn khác") {
                    Toggle("Xóa dấu tiếng Việt", isOn: $viewModel.removeMark)
                }
                
                // Code table conversion
                SettingsGroup(title: "Chuyển đổi bảng mã") {
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Từ:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("", selection: $viewModel.fromCode) {
                                Text("Unicode").tag(0)
                                Text("TCVN3").tag(1)
                                Text("VNI").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sang:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("", selection: $viewModel.toCode) {
                                Text("Unicode").tag(0)
                                Text("TCVN3").tag(1)
                                Text("VNI").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                    }
                }
                
                // Convert button
                HStack {
                    Button("Xóa") {
                        viewModel.clear()
                    }
                    
                    Spacer()
                    
                    Button("Chuyển đổi") {
                        viewModel.convert()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.inputText.isEmpty)
                }
                
                // Output text
                SettingsGroup(title: "Kết quả") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $viewModel.outputText)
                            .font(.body)
                            .frame(height: 100)
                            .border(Color.gray.opacity(0.2), width: 1)
                            .cornerRadius(4)
                        
                        if !viewModel.outputText.isEmpty {
                            Button("Copy kết quả") {
                                viewModel.copyToClipboard()
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

// MARK: - Reusable Components

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(ZKTypography.caption)
                .foregroundColor(ZKColors.textTertiary)
                .textCase(.uppercase)
            
            content
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ZKColors.glassBorder, lineWidth: 1)
                        )
                )
        }
    }
}

struct SettingsRadioButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? ZKColors.accent : ZKColors.textTertiary, lineWidth: 2)
                        .frame(width: 18, height: 18)
                    
                    if isSelected {
                        Circle()
                            .fill(ZKColors.accentGradient)
                            .frame(width: 10, height: 10)
                    }
                }
                
                Text(title)
                    .font(ZKTypography.body)
                    .foregroundColor(isSelected ? ZKColors.textPrimary : ZKColors.textSecondary)
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(ZKAnimations.easeOut, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Input Sources Settings Section

struct InputSourcesSettingsSection: View {
    @StateObject private var viewModel = InputSourcesViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with explanation
                SettingsGroup(title: "Quản lý Input Sources") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ZendyKey có thể tự động bật/tắt tính năng thêm dấu tiếng Việt dựa trên Input Source hiện tại của hệ điều hành.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Divider()

                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Input Source hiện tại:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(viewModel.currentInputSource?.displayName ?? "Unknown")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            Button("Làm mới") {
                                viewModel.refresh()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }

                // Input Sources List
                SettingsGroup(title: "Cấu hình theo Input Source") {
                    VStack(alignment: .leading, spacing: 8) {
                        if viewModel.inputSources.isEmpty {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Đang tải danh sách Input Sources...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            VStack(spacing: 8) {
                                ForEach(viewModel.inputSources) { source in
                                    InputSourceRow(
                                        source: source,
                                        isEnabled: viewModel.isEnabled(for: source.id),
                                        isCurrent: viewModel.currentInputSource?.id == source.id
                                    ) { enabled in
                                        viewModel.setEnabled(enabled, for: source.id)
                                    }
                                }
                            }
                        }

                        Divider()
                            .padding(.top, 8)

                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Bật = ZendyKey sẽ tự động thêm dấu tiếng Việt khi Input Source này được chọn")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Vietnamese Input Sources Detection
                if !viewModel.vietnameseInputSources.isEmpty {
                    SettingsGroup(title: "Input Sources tiếng Việt đã phát hiện") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.vietnameseInputSources) { source in
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(source.displayName)
                                            .font(.body)
                                        Text(source.id)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }

                            Divider()

                            Text("💡 Với các Input Source tiếng Việt khác (Telex, VNI...), bạn có thể tắt ZendyKey để tránh xung đột.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .onAppear {
            viewModel.loadInputSources()
        }
    }
}

// MARK: - Input Source Row

struct InputSourceRow: View {
    let source: InputSourceInfo
    let isEnabled: Bool
    let isCurrent: Bool
    let onToggle: (Bool) -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Current indicator with gradient
            Circle()
                .fill(isCurrent ? ZKColors.accentGradient : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(ZKColors.glassBorder, lineWidth: 1)
                )

            // Source info
            VStack(alignment: .leading, spacing: 2) {
                Text(source.displayName)
                    .font(ZKTypography.body)
                    .foregroundColor(ZKColors.textPrimary)
                Text(source.id)
                    .font(ZKTypography.caption)
                    .foregroundColor(ZKColors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            .toggleStyle(ZKToggleStyle())
            .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? ZKColors.glassBackground : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? ZKColors.glassBorder : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(ZKAnimations.springFast) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Input Sources ViewModel

class InputSourcesViewModel: ObservableObject {
    @Published var inputSources: [InputSourceInfo] = []
    @Published var currentInputSource: InputSourceInfo?

    private var manager: ZKInputSourceManager?
    private var notificationObserver: Any?

    init() {
        manager = ZKInputSourceManager()
        manager?.debugLogCallback = { message in
            logInfo(message, source: "ZKInputSourceManager")
        }

        // Listen for input source changes
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .inputSourceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Auto-refresh when input source changes
            self?.refresh()
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var vietnameseInputSources: [InputSourceInfo] {
        inputSources.filter { ZKInputSourceManager.isVietnameseInputSource($0) }
    }

    func loadInputSources() {
        inputSources = ZKInputSourceManager.getAllInputSources()
        currentInputSource = ZKInputSourceManager.getCurrentInputSource()
    }

    func refresh() {
        loadInputSources()
    }

    func isEnabled(for inputSourceID: String) -> Bool {
        return manager?.isEnabled(for: inputSourceID) ?? true
    }

    func setEnabled(_ enabled: Bool, for inputSourceID: String) {
        manager?.setEnabled(enabled, for: inputSourceID)
        objectWillChange.send()
    }
}

// MARK: - Preview

@available(macOS 13.0, *)
#Preview {
    ZKSettingsView()
}
