//
//  ZKSendKeyStepByStepAppsView.swift
//  ZendyKey
//
//  View for managing SendKeyStepByStep apps - apps where step-by-step key sending is enabled
//  Apps that need character-by-character input instead of bulk replacement
//

import SwiftUI
import AppKit

// MARK: - SendKeyStepByStep Apps Settings Section

struct SendKeyStepByStepAppsSettingsSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel
    @State private var showAppPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Global SendKeyStepByStep toggle
                SettingsGroup(title: "Gửi từng phím") {
                VStack(alignment: .leading, spacing: 12) {
                        Toggle("Bật gửi từng phím", isOn: $viewModel.preferences.sendKeyStepByStep)
                        
                        Text("Gửi ký tự từng phím một thay vì thay thế toàn bộ từ")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textSecondary)
                        
                        Text("Dành cho các ứng dụng có vấn đề với việc thay thế văn bản")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textTertiary)
                    }
                }
                
                // Per-app settings
                SettingsGroup(title: "Ứng dụng gửi từng phím") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Các ứng dụng trong danh sách này sẽ tự động bật chế độ gửi từng phím.")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textSecondary)
                        
                        HStack(spacing: 12) {
                            Button(action: { showAppPicker = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.app")
                                    Text("Thêm ứng dụng")
                                }
                                .font(ZKTypography.caption.bold())
                                .foregroundColor(ZKColors.accent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(ZKColors.accent.opacity(0.15))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            if !viewModel.preferences.sendKeyStepByStepApps.isEmpty {
                                Button(action: {
                                    withAnimation(ZKAnimations.spring) {
                                        viewModel.preferences.sendKeyStepByStepApps.removeAll()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "trash")
                                        Text("Xóa tất cả")
                                    }
                                    .font(ZKTypography.caption.bold())
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.15))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Apps list
                SettingsGroup(title: "Danh sách (\(viewModel.preferences.sendKeyStepByStepApps.count))") {
                    if viewModel.preferences.sendKeyStepByStepApps.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "keyboard.badge.ellipsis")
                                    .font(.system(size: 32))
                                    .foregroundColor(ZKColors.textTertiary)
                                Text("Chưa có ứng dụng nào")
                                    .font(ZKTypography.body)
                                    .foregroundColor(ZKColors.textSecondary)
                            }
                            .padding(.vertical, 24)
                            Spacer()
                        }
                    } else {
                        VStack(spacing: 8) {
                            ForEach(viewModel.preferences.sendKeyStepByStepApps) { app in
                                SendKeyStepByStepAppRow(app: app) {
                                    removeApp(app)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .sheet(isPresented: $showAppPicker) {
            SendKeyStepByStepAppPickerView { selectedApp in
                addApp(selectedApp)
            }
        }
    }
    
    private func addApp(_ app: SendKeyStepByStepApp) {
        // Check if already exists
        guard !viewModel.preferences.sendKeyStepByStepApps.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) else {
            return
        }
        withAnimation(ZKAnimations.spring) {
            viewModel.preferences.sendKeyStepByStepApps.append(app)
        }
    }
    
    private func removeApp(_ app: SendKeyStepByStepApp) {
        withAnimation(ZKAnimations.spring) {
            viewModel.preferences.sendKeyStepByStepApps.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
        }
    }
}

// MARK: - SendKeyStepByStep App Row

struct SendKeyStepByStepAppRow: View {
    let app: SendKeyStepByStepApp
    let onDelete: () -> Void
    @State private var isHovered = false
    @State private var appIcon: NSImage?
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon with glass background
            ZStack {
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ZKColors.glassBackground)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "app")
                                .foregroundColor(ZKColors.textTertiary)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(ZKTypography.body.bold())
                    .foregroundColor(ZKColors.textPrimary)
                Text(app.bundleIdentifier)
                    .font(ZKTypography.caption)
                    .foregroundColor(ZKColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Delete button with hover effect
            Button(action: {
                withAnimation(ZKAnimations.spring) {
                    onDelete()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isHovered ? Color.red.opacity(0.15) : Color.clear)
                        .frame(width: 28, height: 28)
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isHovered ? .red : ZKColors.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(isHovered ? 1.1 : 1.0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? ZKColors.glassBackground : Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovered ? ZKColors.glassBorder : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(ZKAnimations.springFast) {
                isHovered = hovering
            }
        }
        .onAppear {
            loadAppIcon()
        }
    }
    
    private func loadAppIcon() {
        if !app.path.isEmpty {
            appIcon = NSWorkspace.shared.icon(forFile: app.path)
        } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
            appIcon = NSWorkspace.shared.icon(forFile: url.path)
        }
    }
}

// MARK: - App Picker View

struct SendKeyStepByStepAppPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let onSelect: (SendKeyStepByStepApp) -> Void
    
    @State private var searchText = ""
    @State private var runningApps: [RunningAppInfo] = []
    @State private var showingFilePicker = false
    
    struct RunningAppInfo: Identifiable {
        let id = UUID()
        let name: String
        let bundleIdentifier: String
        let path: String
        let icon: NSImage?
    }
    
    var filteredApps: [RunningAppInfo] {
        if searchText.isEmpty {
            return runningApps
        }
        return runningApps.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText) ||
            app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Chọn ứng dụng")
                    .font(ZKTypography.headline)
                    .foregroundColor(ZKColors.textPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ZKColors.textTertiary)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ZKColors.textTertiary)
                TextField("Tìm kiếm ứng dụng...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(ZKColors.glassBackground)
            .cornerRadius(8)
            .padding()
            
            // Options
            HStack {
                Button(action: { showingFilePicker = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text("Chọn từ thư mục")
                    }
                    .font(ZKTypography.caption)
                    .foregroundColor(ZKColors.accent)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("\(filteredApps.count) ứng dụng đang chạy")
                    .font(ZKTypography.caption)
                    .foregroundColor(ZKColors.textTertiary)
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical, 8)
            
            // Running apps list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredApps) { app in
                        Button(action: {
                            let selectedApp = SendKeyStepByStepApp(
                                bundleIdentifier: app.bundleIdentifier,
                                name: app.name,
                                path: app.path
                            )
                            onSelect(selectedApp)
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                if let icon = app.icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(ZKColors.glassBackground)
                                        .frame(width: 28, height: 28)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name)
                                        .font(ZKTypography.body)
                                        .foregroundColor(ZKColors.textPrimary)
                                    Text(app.bundleIdentifier)
                                        .font(ZKTypography.caption)
                                        .foregroundColor(ZKColors.textSecondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 450, height: 500)
        .background(AdaptiveColors.surfaceBackground(for: colorScheme))
        .onAppear {
            loadRunningApps()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.application],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                if let app = SendKeyStepByStepApp(from: url) {
                    onSelect(app)
                    dismiss()
                }
            }
        }
    }
    
    private func loadRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
            .compactMap { app -> RunningAppInfo? in
                guard let bundleId = app.bundleIdentifier,
                      let appName = app.localizedName else { return nil }
                let path = app.bundleURL?.path ?? ""
                return RunningAppInfo(
                    name: appName,
                    bundleIdentifier: bundleId,
                    path: path,
                    icon: app.icon
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
