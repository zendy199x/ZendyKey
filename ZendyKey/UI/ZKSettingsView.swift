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
    case appearance = "Giao diện"
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
        case .appearance: return "paintbrush"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Main Settings View

@available(macOS 13.0, *)
struct ZKSettingsView: View {
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
            }
            .frame(width: 200)
            .background(
                ZStack {
                    Color(hex: "1a1a2e")
                    Color.white.opacity(0.02)
                }
            )
            
            // Separator
            Rectangle()
                .fill(ZKColors.glassBorder)
                .frame(width: 1)
            
            // Content Area
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "16213e"), Color(hex: "1a1a2e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
        .background(Color(hex: "1a1a2e"))
        .preferredColorScheme(.dark)
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
                
                SettingsGroup(title: "Debug") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Bật chế độ Debug", isOn: $viewModel.preferences.debugModeEnabled)
                        
                        Text("Hiển thị cửa sổ debug để theo dõi hoạt động của bộ gõ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // IMKit Mode (Experimental)
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

// MARK: - Appearance Settings Section

struct AppearanceSettingsSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsGroup(title: "Thanh menu") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Biểu tượng menubar:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(MenuBarIconStyle.allCases, id: \.self) { style in
                                SettingsRadioButton(
                                    title: style.displayName,
                                    isSelected: viewModel.preferences.menuBarIconStyle == style
                                ) {
                                    viewModel.preferences.menuBarIconStyle = style
                                }
                            }
                        }
                        .padding(.leading, 8)
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

// MARK: - About Settings Section

struct AboutSettingsSection: View {
    @State private var showDonationDialog = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // App Logo
                if let logo = NSImage(named: "ZendyKeyLogo") {
                    Image(nsImage: logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .padding(.top, 20)
                } else {
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                        .padding(.top, 20)
                }
                
                // App Name & Version
                VStack(spacing: 4) {
                    Text("ZendyKey")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Vietnamese Input Method for macOS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Version \(ZKAppVersion.current)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                Divider()
                    .padding(.horizontal, 80)
                
                // Credits & Donation
                VStack(spacing: 8) {
                    Text("Made with ❤️ & ☕")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showDonationDialog = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "cup.and.saucer.fill")
                            Text("Buy me a coffee")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Divider()
                    .padding(.horizontal, 80)

                // Update Check Section - Using Sparkle
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        Text("Kiểm tra phiên bản mới")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button("Kiểm tra cập nhật") {
                        // Temporarily lower the Settings window level so Sparkle dialog appears on top
                        if let settingsWindow = NSApp.keyWindow {
                            settingsWindow.level = .normal
                        }
                        
                        // Use ZKAppDelegate.shared for reliable access
                        if let appDelegate = ZKAppDelegate.shared {
                            appDelegate.checkForUpdatesFromUI()
                        } else if let delegate = NSApplication.shared.delegate as? ZKAppDelegate {
                            delegate.checkForUpdatesFromUI()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Copyright
                Text("Inspired by Openkey & Unikey.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showDonationDialog) {
            ZKDonationView()
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
