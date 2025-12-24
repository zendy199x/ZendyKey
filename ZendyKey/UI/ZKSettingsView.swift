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
    case hotkeys = "Phím tắt"
    case quickTyping = "Gõ nhanh"
    case advanced = "Nâng cao"
    case inputSources = "Input Sources"
    case excludedApps = "Loại trừ"
    case macro = "Macro"
    case convertTool = "Chuyển đổi"
    case appearance = "Hệ thống"
    case statistics = "Thống kê"
    case about = "Giới thiệu"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .hotkeys: return "command.square"
        case .statistics: return "chart.bar.xaxis"
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
    @Namespace private var sidebarAnimation

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
                        Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
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
                                namespace: sidebarAnimation,
                                action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
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
                    case .hotkeys:
                        HotkeysSettingsSection(viewModel: viewModel)
                    case .statistics:
                        ZKStatisticsSection()
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
    @State private var isVietnameseEnabled: Bool = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Vietnamese Toggle + Sound
                ZKSection("Chế độ gõ") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Vietnamese toggle row
                        ZKToggleRow(
                            icon: "character",
                            iconText: "VI",
                            title: "Gõ tiếng Việt",
                            subtitle: isVietnameseEnabled ? "Đang gõ tiếng Việt 🇻🇳" : "Đang gõ tiếng Anh 🇬🇧"
                        ) {
                            Toggle("", isOn: $isVietnameseEnabled)
                                .toggleStyle(ZKToggleStyle())
                                .labelsHidden()
                        }
                        .onChange(of: isVietnameseEnabled) { newValue in
                            NotificationCenter.default.post(
                                name: .toggleVietnameseFromSettings,
                                object: nil,
                                userInfo: ["enabled": newValue]
                            )
                        }
                        
                        Divider()
                        
                        // Sound toggle row
                        ZKToggleRow(
                            icon: "speaker.wave.2.fill",
                            title: "Phát âm thanh khi chuyển chế độ",
                            subtitle: "Phát beep khi bấm phím tắt"
                        ) {
                            Toggle("", isOn: $viewModel.preferences.beepOnToggle)
                                .toggleStyle(ZKToggleStyle())
                                .labelsHidden()
                        }
                    }
                }
                .onAppear {
                    // Listen for external changes
                    NotificationCenter.default.addObserver(
                        forName: .vietnameseModeDidChange,
                        object: nil,
                        queue: .main
                    ) { notification in
                        if let enabled = notification.userInfo?["enabled"] as? Bool {
                            isVietnameseEnabled = enabled
                        }
                    }
                    // Request current state
                    NotificationCenter.default.post(name: .requestVietnameseState, object: nil)
                }
                
                // Input Method
                ZKSection("Kiểu gõ") {
                    ZKInputMethodPicker(selection: $viewModel.preferences.inputMethod)
                }
                
                // Code Table
                ZKSection( "Bảng mã") {
                    ZKCodeTablePicker(selection: $viewModel.preferences.codeTable)
                }
                
                // Basic Options
                ZKSection( "Tùy chọn") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Kiểu gõ hiện đại (oà/uý)", isOn: $viewModel.preferences.modernStyle)
                        Toggle("Kiểm tra chính tả", isOn: $viewModel.preferences.spellCheckEnabled)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Kiểm tra ngữ pháp", isOn: $viewModel.preferences.grammarCheckEnabled)
                            
                            Text("Tự động sửa lỗi ngữ pháp: ưo→ươ, điều chỉnh vị trí dấu thanh")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
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

// MARK: - Hotkeys Settings Section

enum HotkeyType {
    case toggleVietnamese
    case inputMethod
    case codeTable
}

struct HotkeysSettingsSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    // Single recording mode - only one row can record at a time
    @State private var activeRecordingId: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hotkey shortcuts group
                ZKSection("Tổ hợp phím tắt") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Toggle Vietnamese
                        ZKUnifiedHotkeyRow(
                            rowId: "toggle",
                            icon: "globe",
                            title: "Bật/tắt gõ tiếng Việt",
                            subtitle: "Mặc định: ⌘⇧V",
                            hotkey: $viewModel.preferences.toggleHotkey,
                            activeRecordingId: $activeRecordingId,
                            isConflict: { isHotkeyConflict($0, for: .toggleVietnamese) }
                        )
                        
                        Divider()
                        
                        // Switch Input Method
                        ZKUnifiedHotkeyRow(
                            rowId: "inputMethod",
                            icon: "keyboard",
                            title: "Đổi kiểu gõ",
                            subtitle: "Chuyển đổi giữa các kiểu gõ Telex, VNI, VIQR,...",
                            hotkeyOptional: $viewModel.preferences.inputMethodHotkey,
                            placeholder: "Chưa đặt",
                            activeRecordingId: $activeRecordingId,
                            isConflict: { isHotkeyConflict($0, for: .inputMethod) }
                        )
                        
                        Divider()
                        
                        // Switch Code Table
                        ZKUnifiedHotkeyRow(
                            rowId: "codeTable",
                            icon: "tablecells",
                            title: "Đổi bảng mã",
                            subtitle: "Chuyển đổi Unicode, TCVN3, VNI Windows,...",
                            hotkeyOptional: $viewModel.preferences.codeTableHotkey,
                            placeholder: "Chưa đặt",
                            activeRecordingId: $activeRecordingId,
                            isConflict: { isHotkeyConflict($0, for: .codeTable) }
                        )
                    }
                }
                
                // Pause Vietnamese temporarily
                ZKSection("Phím tạm dừng gõ tiếng Việt") {
                    VStack(alignment: .leading, spacing: 16) {
                        ZKToggleRow(
                            icon: "pause.fill",
                            title: "Bật tính năng tạm dừng",
                            subtitle: "Giữ phím để tạm thời gõ tiếng Anh"
                        ) {
                            Toggle("", isOn: $viewModel.preferences.pauseKeyEnabled)
                                .toggleStyle(ZKToggleStyle())
                                .labelsHidden()
                        }
                        
                        if viewModel.preferences.pauseKeyEnabled {
                            Divider()
                            
                            // Key Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Chọn phím tạm dừng")
                                    .font(ZKTypography.caption.bold())
                                    .foregroundColor(ZKColors.textPrimary)
                                
                                HStack(spacing: 12) {
                                    ZKPauseKeyButton(
                                        symbol: "⌃",
                                        name: "Control",
                                        keyCode: 59,
                                        selectedKeyCode: $viewModel.preferences.pauseKey,
                                        selectedKeyName: $viewModel.preferences.pauseKeyName
                                    )
                                    ZKPauseKeyButton(
                                        symbol: "⌥",
                                        name: "Option",
                                        keyCode: 58,
                                        selectedKeyCode: $viewModel.preferences.pauseKey,
                                        selectedKeyName: $viewModel.preferences.pauseKeyName
                                    )
                                }
                                
                                Text("Mặc định: Option. Ví dụ: giữ ⌥ gõ \"email\" → thả ⌥")
                                    .font(ZKTypography.caption)
                                    .foregroundColor(ZKColors.textTertiary)
                            }
                            
                            // Conflict warning
                            if viewModel.preferences.pauseKeyEnabled && viewModel.preferences.restoreOnEscape &&
                               viewModel.preferences.pauseKey == viewModel.preferences.restoreKey.rawValue {
                                ZKConflictWarningView(message: "Phím tạm dừng trùng với phím khôi phục")
                            }
                        }
                    }
                }
                
                // Restore to original (without tones)
                ZKSection("Phím khôi phục nguyên gốc") {
                    VStack(alignment: .leading, spacing: 16) {
                        ZKToggleRow(
                            icon: "arrow.counterclockwise",
                            title: "Bật khôi phục nguyên gốc",
                            subtitle: "Khôi phục từ về dạng chưa bỏ dấu"
                        ) {
                            Toggle("", isOn: $viewModel.preferences.restoreOnEscape)
                                .toggleStyle(ZKToggleStyle())
                                .labelsHidden()
                        }
                        
                        if viewModel.preferences.restoreOnEscape {
                            Divider()
                            
                            // Key Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Chọn phím khôi phục")
                                    .font(ZKTypography.caption.bold())
                                    .foregroundColor(ZKColors.textPrimary)
                                
                                HStack(spacing: 12) {
                                    ZKRestoreKeyButton(
                                        symbol: "⎋",
                                        name: "ESC",
                                        restoreKey: .esc,
                                        selectedKey: $viewModel.preferences.restoreKey
                                    )
                                    ZKRestoreKeyButton(
                                        symbol: "⌥",
                                        name: "Option",
                                        restoreKey: .option,
                                        selectedKey: $viewModel.preferences.restoreKey
                                    )
                                    ZKRestoreKeyButton(
                                        symbol: "⌃",
                                        name: "Control",
                                        restoreKey: .control,
                                        selectedKey: $viewModel.preferences.restoreKey
                                    )
                                }
                                
                                Text("Mặc định: ESC. Ví dụ: \"việt\" → ESC → \"vieejt\"")
                                    .font(ZKTypography.caption)
                                    .foregroundColor(ZKColors.textTertiary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .onChange(of: activeRecordingId) { newValue in
            // Notify app delegate about recording state to disable hotkeys during recording
            ZKAppDelegate.shared?.setHotkeyRecordingState(newValue != nil)
        }
        .onChange(of: viewModel.preferences.inputMethodHotkey) { _ in
            // Trigger auto-save and menu rebuild
            viewModel.objectWillChange.send()
            NotificationCenter.default.post(name: .hotkeySettingsDidChange, object: nil)
        }
        .onChange(of: viewModel.preferences.codeTableHotkey) { _ in
            // Trigger auto-save and menu rebuild
            viewModel.objectWillChange.send()
            NotificationCenter.default.post(name: .hotkeySettingsDidChange, object: nil)
        }
        .onDisappear {
            // Reset recording state when view disappears
            ZKAppDelegate.shared?.setHotkeyRecordingState(false)
        }
    }
    
    // MARK: - Conflict Detection
    
    private func isHotkeyConflict(_ newHotkey: Hotkey, for type: HotkeyType) -> Bool {
        let toggleHotkey = viewModel.preferences.toggleHotkey
        let inputMethodHotkey = viewModel.preferences.inputMethodHotkey
        let codeTableHotkey = viewModel.preferences.codeTableHotkey
        
        switch type {
        case .toggleVietnamese:
            // Check against input method and code table hotkeys
            if let imHotkey = inputMethodHotkey, hotkeyEquals(newHotkey, imHotkey) {
                return true
            }
            if let ctHotkey = codeTableHotkey, hotkeyEquals(newHotkey, ctHotkey) {
                return true
            }
        case .inputMethod:
            // Check against toggle and code table hotkeys
            if hotkeyEquals(newHotkey, toggleHotkey) {
                return true
            }
            if let ctHotkey = codeTableHotkey, hotkeyEquals(newHotkey, ctHotkey) {
                return true
            }
        case .codeTable:
            // Check against toggle and input method hotkeys
            if hotkeyEquals(newHotkey, toggleHotkey) {
                return true
            }
            if let imHotkey = inputMethodHotkey, hotkeyEquals(newHotkey, imHotkey) {
                return true
            }
        }
        
        return false
    }
    
    private func hotkeyEquals(_ a: Hotkey, _ b: Hotkey) -> Bool {
        return a.keyCode == b.keyCode && a.modifiers == b.modifiers
    }
}

struct ZKUnifiedHotkeyRow: View {
    let rowId: String
    let icon: String
    let title: String
    var subtitle: String? = nil
    var defaultHotkey: Hotkey? = nil
    var placeholder: String = "Chưa đặt"
    var iconBackground: AnyShapeStyle? = nil
    
    // Conflict detection
    var isConflict: ((Hotkey) -> Bool)? = nil
    
    // Shared recording state
    @Binding var activeRecordingId: String?
    
    // Fixed width for alignment
    private let recorderWidth: CGFloat = 120
    private let clearButtonWidth: CGFloat = 30
    
    // For required hotkey
    @Binding var hotkey: Hotkey
    var hotkeyOptional: Binding<Hotkey?>? = nil
    
    // Local state
    @State private var isHovered = false
    @State private var showConflictWarning = false
    @State private var conflictMessage = ""
    
    // Computed property for recording state
    private var isRecording: Bool {
        activeRecordingId == rowId
    }
    
    // Initializer for required hotkey
    init(rowId: String, icon: String, title: String, subtitle: String? = nil, hotkey: Binding<Hotkey>, defaultHotkey: Hotkey = Hotkey(keyCode: 9, modifiers: [.command, .shift]), iconBackground: AnyShapeStyle? = nil, activeRecordingId: Binding<String?>, isConflict: ((Hotkey) -> Bool)? = nil) {
        self.rowId = rowId
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._hotkey = hotkey
        self.hotkeyOptional = nil
        self.defaultHotkey = defaultHotkey
        self.placeholder = ""
        self.iconBackground = iconBackground
        self._activeRecordingId = activeRecordingId
        self.isConflict = isConflict
    }
    
    // Initializer for optional hotkey
    init(rowId: String, icon: String, title: String, subtitle: String? = nil, hotkeyOptional: Binding<Hotkey?>, placeholder: String = "Chưa đặt", iconBackground: AnyShapeStyle? = nil, activeRecordingId: Binding<String?>, isConflict: ((Hotkey) -> Bool)? = nil) {
        self.rowId = rowId
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._hotkey = .constant(Hotkey(keyCode: 0, modifiers: []))
        self.hotkeyOptional = hotkeyOptional
        self.defaultHotkey = nil
        self.placeholder = placeholder
        self.iconBackground = iconBackground
        self._activeRecordingId = activeRecordingId
        self.isConflict = isConflict
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Use ZKToggleRow for icon/title/subtitle with custom trailing content
            ZKToggleRow(
                icon: icon,
                iconBackground: iconBackground,
                title: title,
                subtitle: subtitle
            ) {
                HStack(spacing: 8) {
                    // Recorder button
                    Button(action: startRecording) {
                        HStack(spacing: 8) {
                            Image(systemName: isRecording ? "keyboard.badge.ellipsis" : "keyboard")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(isRecording ? ZKColors.accent : ZKColors.textSecondary)
                            
                            Text(displayText)
                                .font(ZKTypography.body.weight(hasHotkey ? .semibold : .regular))
                                .foregroundColor(isRecording ? ZKColors.accent : (hasHotkey ? ZKColors.textPrimary : ZKColors.textTertiary))
                                .lineLimit(1)
                        }
                        .frame(width: recorderWidth, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isRecording ? ZKColors.accent.opacity(0.1) : ZKColors.glassBackground.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isRecording ? ZKColors.accent : ZKColors.glassBorder, lineWidth: 1)
                                )
                        )
                        .scaleEffect(isHovered ? 1.02 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isHovered = hovering
                        }
                    }
                    .background(
                        UnifiedKeyEventHandler(
                            isRecording: Binding(
                                get: { isRecording },
                                set: { newValue in
                                    if newValue {
                                        activeRecordingId = rowId
                                    } else if activeRecordingId == rowId {
                                        activeRecordingId = nil
                                    }
                                }
                            ),
                            hotkey: hotkeyOptional != nil ? nil : $hotkey,
                            hotkeyOptional: hotkeyOptional,
                            onConflict: { hotkey in
                                showConflict(for: hotkey)
                            },
                            isConflict: isConflict
                        )
                    )
                    
                    // Clear button
                    Button(action: clearHotkey) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(shouldShowClearButton ? ZKColors.textTertiary : Color.clear)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    .disabled(!shouldShowClearButton)
                    .frame(width: clearButtonWidth)
                }
            }
            
            // Inline conflict warning
            if showConflictWarning {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 12))
                    
                    Text(conflictMessage)
                        .font(ZKTypography.caption)
                        .foregroundStyle(.orange)
                }
                .padding(.leading, 50)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showConflictWarning)
    }
    
    private func startRecording() {
        // Immediately disable hotkeys to prevent toggle during recording
        ZKAppDelegate.shared?.setHotkeyRecordingState(true)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            activeRecordingId = rowId
        }
    }
    
    private func showConflict(for hotkey: Hotkey) {
        withAnimation(.easeInOut(duration: 0.2)) {
            showConflictWarning = true
            conflictMessage = "Phím tắt \(hotkey.displayString) đã được sử dụng"
        }
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showConflictWarning = false
            }
        }
    }
    
    private var displayText: String {
        if isRecording {
            return "Nhấn phím..."
        }
        if let binding = hotkeyOptional {
            if let hk = binding.wrappedValue {
                return hk.displayString
            }
            return placeholder
        }
        return hotkey.displayString
    }
    
    private var hasHotkey: Bool {
        if let binding = hotkeyOptional {
            return binding.wrappedValue != nil
        }
        return true
    }
    
    private var shouldShowClearButton: Bool {
        if let binding = hotkeyOptional {
            return binding.wrappedValue != nil
        }
        // For required hotkey, show clear if not default
        if let defaultHk = defaultHotkey {
            return hotkey.keyCode != defaultHk.keyCode || hotkey.modifiers != defaultHk.modifiers
        }
        return true
    }
    
    private func clearHotkey() {
        withAnimation(.easeInOut(duration: 0.2)) {
            // Exit recording mode first
            if activeRecordingId == rowId {
                activeRecordingId = nil
            }
            
            if let _ = hotkeyOptional {
                hotkeyOptional?.wrappedValue = nil
            } else if let defaultHk = defaultHotkey {
                // Reset to default for required hotkey
                hotkey = defaultHk
            }
        }
    }
}

// MARK: - Unified Key Event Handler

struct UnifiedKeyEventHandler: NSViewRepresentable {
    @Binding var isRecording: Bool
    var hotkey: Binding<Hotkey>?
    var hotkeyOptional: Binding<Hotkey?>?
    var onConflict: ((Hotkey) -> Void)?
    var isConflict: ((Hotkey) -> Bool)?
    
    func makeNSView(context: Context) -> NSView {
        let view = UnifiedKeyCaptureView()
        view.onKeyPress = { keyCode, modifiers in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                // Validate: must have at least 1 modifier
                if modifiers.isEmpty {
                    // Single key without modifier - don't accept
                    isRecording = false
                    return
                }
                
                let newHotkey = Hotkey(keyCode: keyCode, modifiers: modifiers, isModifierOnly: false)
                
                // Check for conflict before setting
                if let isConflict = isConflict, isConflict(newHotkey) {
                    onConflict?(newHotkey)
                    isRecording = false
                    return
                }
                
                if let hotkeyOptional = hotkeyOptional {
                    hotkeyOptional.wrappedValue = newHotkey
                } else if let hotkey = hotkey {
                    hotkey.wrappedValue = newHotkey
                }
                isRecording = false
            }
        }
        view.onCancel = {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isRecording = false
            }
        }
        DispatchQueue.main.async {
            context.coordinator.view = view
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let keyView = nsView as? UnifiedKeyCaptureView {
            keyView.isRecording = isRecording
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var view: UnifiedKeyCaptureView?
    }
}

class UnifiedKeyCaptureView: NSView {
    var onKeyPress: ((UInt16, ModifierFlags) -> Void)?
    var onCancel: (() -> Void)?
    var isRecording = false {
        didSet {
            if isRecording {
                window?.makeFirstResponder(self)
            }
        }
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        // ESC to cancel
        if event.keyCode == 53 {
            DispatchQueue.main.async { [weak self] in
                self?.onCancel?()
            }
            return
        }
        
        let keyCode = UInt16(event.keyCode)
        var modifiers = ModifierFlags()
        
        if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
        if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
        if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
        if event.modifierFlags.contains(.command) { modifiers.insert(.command) }
        
        DispatchQueue.main.async { [weak self] in
            self?.onKeyPress?(keyCode, modifiers)
        }
    }
}

// MARK: - Hotkey Row Component

struct ZKHotkeyRow: View {
    let icon: String
    let title: String
    @Binding var hotkey: Hotkey
    var hotkeyOptional: Binding<Hotkey?>? = nil
    var isOptional: Bool = false
    var placeholder: String = ""
    
    @State private var isHovered = false
    
    // For required hotkey
    init(icon: String, title: String, hotkey: Binding<Hotkey>, isOptional: Bool = false) {
        self.icon = icon
        self.title = title
        self._hotkey = hotkey
        self.hotkeyOptional = nil
        self.isOptional = isOptional
        self.placeholder = ""
    }
    
    // For optional hotkey
    init(icon: String, title: String, hotkeyOptional: Binding<Hotkey?>, isOptional: Bool = true, placeholder: String = "Chưa đặt") {
        self.icon = icon
        self.title = title
        self._hotkey = .constant(Hotkey(keyCode: 0, modifiers: []))
        self.hotkeyOptional = hotkeyOptional
        self.isOptional = isOptional
        self.placeholder = placeholder
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ZKColors.accent.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ZKColors.accentGradient)
            }
            
            // Title
            Text(title)
                .font(ZKTypography.body)
                .foregroundColor(ZKColors.textPrimary)
            
            Spacer()
            
            // Hotkey display + recorder
            if let optionalBinding = hotkeyOptional {
                ZKOptionalHotkeyRecorderView(hotkey: optionalBinding, placeholder: placeholder)
                    .frame(minWidth: 150)
            } else {
                ZKHotkeyRecorderView(hotkey: $hotkey)
                    .frame(minWidth: 150)
            }
            
            // Clear button
            if shouldShowClearButton {
                Button(action: clearHotkey) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ZKColors.textTertiary)
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var shouldShowClearButton: Bool {
        if let binding = hotkeyOptional {
            return binding.wrappedValue != nil
        }
        return false
    }
    
    private func clearHotkey() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if hotkeyOptional != nil {
                hotkeyOptional?.wrappedValue = nil
            }
        }
    }
}

// MARK: - Optional Hotkey Recorder View

struct ZKOptionalHotkeyRecorderView: View {
    @Binding var hotkey: Hotkey?
    var placeholder: String = "Chưa đặt"
    
    @State private var isRecording = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isRecording = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isRecording ? "keyboard.badge.ellipsis" : "keyboard")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isRecording ? ZKColors.accent : ZKColors.textSecondary)
                
                Text(displayText)
                    .font(ZKTypography.body.weight(hotkey != nil ? .semibold : .regular))
                    .foregroundColor(isRecording ? ZKColors.accent : (hotkey != nil ? ZKColors.textPrimary : ZKColors.textTertiary))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isRecording ? ZKColors.accent.opacity(0.1) : ZKColors.glassBackground.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isRecording ? ZKColors.accent : ZKColors.glassBorder, lineWidth: 1)
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .background(OptionalKeyEventHandler(isRecording: $isRecording, hotkey: $hotkey))
    }
    
    private var displayText: String {
        if isRecording {
            return "Nhấn phím..."
        }
        if let hk = hotkey {
            return hk.displayString
        }
        return placeholder
    }
}

// MARK: - Optional Key Event Handler

struct OptionalKeyEventHandler: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var hotkey: Hotkey?
    
    func makeNSView(context: Context) -> NSView {
        let view = OptionalKeyCaptureView()
        view.onKeyPress = { keyCode, modifiers in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                hotkey = Hotkey(keyCode: keyCode, modifiers: modifiers, isModifierOnly: false)
                isRecording = false
            }
        }
        view.onCancel = {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isRecording = false
            }
        }
        DispatchQueue.main.async {
            context.coordinator.view = view
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let keyView = nsView as? OptionalKeyCaptureView {
            keyView.isRecording = isRecording
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var view: OptionalKeyCaptureView?
    }
}

class OptionalKeyCaptureView: NSView {
    var onKeyPress: ((UInt16, ModifierFlags) -> Void)?
    var onCancel: (() -> Void)?
    var isRecording = false {
        didSet {
            if isRecording {
                window?.makeFirstResponder(self)
            }
        }
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        // ESC to cancel
        if event.keyCode == 53 {
            DispatchQueue.main.async { [weak self] in
                self?.onCancel?()
            }
            return
        }
        
        let keyCode = UInt16(event.keyCode)
        var modifiers = ModifierFlags()
        
        if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
        if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
        if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
        if event.modifierFlags.contains(.command) { modifiers.insert(.command) }
        
        DispatchQueue.main.async { [weak self] in
            self?.onKeyPress?(keyCode, modifiers)
        }
    }
}

// MARK: - Quick Typing Settings Section

struct QuickTypingSettingsSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ZKSection( "Quick Telex") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Bật Quick Telex", isOn: $viewModel.preferences.quickTelexEnabled)
                        
                        Text("cc→ch, gg→gi, kk→kh, nn→ng, pp→ph, qq→qu, tt→th")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                ZKSection( "Quick Consonant - Đầu từ") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Bật Quick Start Consonant", isOn: $viewModel.preferences.quickStartConsonantEnabled)
                        
                        Text("f→ph, j→gi, w→qu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                ZKSection( "Quick Consonant - Cuối từ") {
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
                ZKSection( "Chính tả & Viết hoa") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Khôi phục nếu sai chính tả", isOn: $viewModel.preferences.restoreIfWrongSpelling)
                        Toggle("Tự động viết hoa chữ đầu câu", isOn: $viewModel.preferences.upperCaseFirstChar)
                        Toggle("Cho phép phụ âm Z, F, W, J", isOn: $viewModel.preferences.allowConsonantZFWJ)
                    }
                }
                
                ZKSection( "Đặt dấu") {
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
                
                ZKSection( "Telex") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Bỏ qua w→ư", isOn: $viewModel.preferences.skipWShortcut)
                        
                        Text("Giữ 'w' là 'w' thay vì chuyển thành 'ư' ở đầu từ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                ZKSection( "Ghi nhớ ứng dụng") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Nhớ ngôn ngữ theo ứng dụng", isOn: $viewModel.preferences.perAppModeEnabled)
                        
                        Text("Tự động nhớ Việt/Anh cho từng ứng dụng")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                ZKSection( "Tạm tắt") {
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
                
                ZKSection( "Smart Switch") {
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
                        
                        Divider()
                        
                        // Remember Code Table Per App (OpenKey vRememberCode)
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Nhớ bảng mã theo ứng dụng", isOn: $viewModel.preferences.rememberCodeTablePerApp)

                            Text("Tự động chuyển bảng mã (VNI/TCVN3/Unicode) theo từng app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Preserve Vietnamese with Other Language (OpenKey vOtherLanguage)
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Giữ trạng thái khi dùng bàn phím khác", isOn: $viewModel.preferences.preserveVietnameseModeWithOtherLanguage)

                            Text("Giữ chế độ tiếng Việt khi chuyển sang keyboard Hàn/Nhật/Trung, sau đó tự động khôi phục")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Window Title Rules
                ZKSection( "Quy tắc theo Window Title") {
                    if #available(macOS 13.0, *) {
                        ZKWindowTitleRulesView()
                    } else {
                        Text("Tính năng này yêu cầu macOS 13.0 trở lên")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Compatibility Settings
                ZKSection( "Tương thích") {
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
                
                // Per-App SendKeyStepByStep  
                ZKSection( "Ứng dụng cần gửi từng phím") {
                    SendKeyStepByStepAppsSettingsSection(viewModel: viewModel)
                }
                
                // IMKit Mode (Experimental) - Placed before Debug
                ZKSection( "Input Method Kit (Thử nghiệm)") {
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
                ZKSection( "Debug") {
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

@available(macOS 13.0, *)
struct AppearanceSettingsSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var hasAccessibilityPermission = AXIsProcessTrusted()
    @State private var showResetConfirmation = false
    
    private let permissionCheckTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Accessibility Permission
                ZKSection( "Quyền truy cập") {
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
                ZKSection( "Giao diện") {
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
                ZKSection( "Âm thanh") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Phát âm thanh khi chuyển ngôn ngữ", isOn: $viewModel.preferences.beepOnToggle)
                        
                        Text("Phát âm thanh khi bật/tắt tiếng Việt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Menu Bar Icon Settings
                ZKSection( "Icon thanh Menu") {
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
                
                ZKSection( "Dock") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Hiển thị biểu tượng trên thanh Dock", isOn: $viewModel.preferences.showDockIcon)
                        
                        Text("Khi bật, ZendyKey sẽ hiển thị icon trên Dock như các ứng dụng thông thường")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                ZKSection( "Khởi động") {
                    Toggle("Khởi động cùng hệ thống", isOn: $viewModel.preferences.startAtLogin)
                }
                
                // Beep Volume Slider
                if viewModel.preferences.beepOnToggle {
                    ZKSection( "Âm lượng") {
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
                
                // Reset to Defaults
                ZKSection( "Khôi phục mặc định") {
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
        .overlay {
            if showResetConfirmation {
                ZKSettingsResetConfirmationOverlay(
                    colorScheme: colorScheme,
                    onConfirm: {
                        resetToDefaults()
                        showResetConfirmation = false
                    },
                    onCancel: {
                        showResetConfirmation = false
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.3), value: showResetConfirmation)
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
                                .fill(ZKColors.donationGradient)
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
                Text("Made with Zendy199x in Vietnam")
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

// MARK: - About Info Card Component

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
                ZKSection( "Cài đặt Macro") {
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
                ZKSection( "Thêm macro mới") {
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
                ZKSection( "Danh sách macro (\(viewModel.macros.count))") {
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
                ZKSection( "Văn bản gốc") {
                    TextEditor(text: $viewModel.inputText)
                        .font(.body)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.2), width: 1)
                        .cornerRadius(4)
                }
                
                // Conversion options
                ZKSection( "Chuyển đổi chữ hoa/thường") {
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
                
                ZKSection( "Tùy chọn khác") {
                    Toggle("Xóa dấu tiếng Việt", isOn: $viewModel.removeMark)
                }
                
                // Code table conversion
                ZKSection( "Chuyển đổi bảng mã") {
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
                ZKSection( "Kết quả") {
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

// MARK: - Input Method Picker with Premium Design

struct ZKInputMethodPicker: View {
    @Binding var selection: InputMethod
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Segmented buttons
            HStack(spacing: 0) {
                ForEach(InputMethod.orderedCases, id: \.self) { method in
                    ZKInputMethodButton(
                        method: method,
                        isSelected: selection == method,
                        namespace: animation
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selection = method
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(ZKColors.glassBackground.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ZKColors.glassBorder, lineWidth: 1)
            )
            
            // Dynamic description
            Text(selection.description)
                .font(ZKTypography.caption)
                .foregroundColor(ZKColors.textTertiary)
                .animation(.easeInOut(duration: 0.2), value: selection)
        }
    }
}

struct ZKInputMethodButton: View {
    let method: InputMethod
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(method.displayName)
                .font(ZKTypography.body.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : (isHovered ? ZKColors.textPrimary : ZKColors.textSecondary))
                .animation(.easeInOut(duration: 0.15), value: isHovered)
                .frame(minWidth: 80)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        ZKColors.accentGradient
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .matchedGeometryEffect(id: "SelectedIndicator", in: namespace)
                    } else if isHovered {
                        Color.white.opacity(0.08)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Code Table Picker (Modern Grid with Sliding Animation)

struct ZKCodeTablePicker: View {
    @Binding var selection: CodeTable
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    
    // Grid layout: 2 columns
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(CodeTable.allCases, id: \.self) { table in
                ZKCodeTableButton(
                    table: table,
                    isSelected: selection == table,
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selection = table
                    }
                }
            }
        }
    }
}

struct ZKCodeTableButton: View {
    let table: CodeTable
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Selection indicator circle
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : ZKColors.textTertiary.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    
                    if isSelected {
                        Circle()
                            .fill(ZKColors.accentGradient)
                            .frame(width: 18, height: 18)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                Text(table.displayName)
                    .font(ZKTypography.body.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (isHovered ? ZKColors.textPrimary : ZKColors.textSecondary))
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    ZKColors.accentGradient
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .matchedGeometryEffect(id: "CodeTableSelectedIndicator", in: namespace)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.08))
                }
            }
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// SettingsGroup removed - using ZKSection from Components folder

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
                ZKSection( "Quản lý Input Sources") {
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
                ZKSection( "Cấu hình theo Input Source") {
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
                    ZKSection( "Input Sources tiếng Việt đã phát hiện") {
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

// MARK: - Settings Reset Confirmation Overlay

@available(macOS 13.0, *)
struct ZKSettingsResetConfirmationOverlay: View {
    let colorScheme: ColorScheme
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var isHoveringConfirm = false
    @State private var isHoveringCancel = false
    
    var body: some View {
        ZStack {
            // Backdrop
            Rectangle()
                .fill(AdaptiveColors.cardBackground(for: colorScheme).opacity(0.9))
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Dialog card
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    GradientIcon(systemName: "arrow.counterclockwise", size: 28)
                    
                    Text("Khôi phục mặc định?")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AdaptiveColors.textPrimary(for: colorScheme))
                    
                    Text("Tất cả cài đặt sẽ được đặt lại về mặc định.\nDữ liệu macro sẽ được giữ nguyên.\nHành động này không thể hoàn tác.")
                        .font(ZKTypography.body)
                        .foregroundColor(AdaptiveColors.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                
                // Buttons
                VStack(spacing: 10) {
                    // Confirm
                    Button(action: onConfirm) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13))
                            Text("Khôi phục")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(ZKColors.dangerGradient)
                        )
                        .foregroundColor(.white)
                        .scaleEffect(isHoveringConfirm ? 1.02 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHoveringConfirm = $0 }
                    
                    // Cancel
                    Button(action: onCancel) {
                        Text("Hủy")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AdaptiveColors.glassBackground(for: colorScheme))
                            )
                            .foregroundColor(AdaptiveColors.textSecondary(for: colorScheme))
                            .scaleEffect(isHoveringCancel ? 1.02 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHoveringCancel = $0 }
                }
            }
            .padding(24)
            .frame(width: 300)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AdaptiveColors.cardBackground(for: colorScheme))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 20, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AdaptiveColors.glassBorder(for: colorScheme), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

@available(macOS 13.0, *)
#Preview {
    ZKSettingsView()
}

