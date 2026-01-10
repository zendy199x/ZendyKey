//
//  ZKExcludedAppsView.swift
//  ZendyKey
//
//  View for managing excluded apps (apps where Vietnamese input is disabled)
//

import SwiftUI
import AppKit

// MARK: - Excluded Apps Settings Section

struct ExcludedAppsSettingsSection: View {
    @ObservedObject var viewModel: ZKPreferencesViewModel
    @StateObject private var excludedAppsVM = ZKExcludedAppsViewModel()
    @State private var showAppPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ZKSection( "Loại trừ ứng dụng") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Các ứng dụng trong danh sách này sẽ không hỗ trợ gõ tiếng Việt.")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textSecondary)
                        
                        HStack(spacing: 12) {
                            ZKGradientButton.primary(
                                title: "Thêm ứng dụng",
                                icon: "plus.app"
                            ) {
                                showAppPicker = true
                            }
                            
                            Spacer()
                            
                            if !viewModel.preferences.excludedApps.isEmpty {
                                Button(action: {
                                    withAnimation(ZKAnimations.spring) {
                                        viewModel.preferences.excludedApps.removeAll()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12, weight: .medium))
                                        Text("Xóa tất cả")
                                            .font(ZKTypography.caption)
                                    }
                                    .foregroundColor(Color.red.opacity(0.9))
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
                
                // Excluded apps list
                ZKSection( "Danh sách ứng dụng loại trừ (\(viewModel.preferences.excludedApps.count))") {
                    if viewModel.preferences.excludedApps.isEmpty {
                        VStack(spacing: 12) {
                            GradientIcon(systemName: "app.dashed", size: 32)
                            Text("Chưa có ứng dụng nào")
                                .font(ZKTypography.body)
                                .foregroundColor(ZKColors.textSecondary)
                            Text("Thêm ứng dụng để tắt gõ tiếng Việt khi sử dụng")
                                .font(ZKTypography.caption)
                                .foregroundColor(ZKColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.preferences.excludedApps) { app in
                                ExcludedAppRow(app: app) {
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
            AppPickerView { selectedApp in
                addApp(selectedApp)
            }
        }
    }
    
    private func addApp(_ app: ExcludedApp) {
        // Check if already exists
        guard !viewModel.preferences.excludedApps.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) else {
            return
        }
        viewModel.preferences.excludedApps.append(app)
    }
    
    private func removeApp(_ app: ExcludedApp) {
        viewModel.preferences.excludedApps.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
    }
}

// MARK: - Excluded App Row

struct ExcludedAppRow: View {
    let app: ExcludedApp
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
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ZKColors.glassBackground)
                        .frame(width: 36, height: 36)
                    Image(systemName: "app.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(ZKColors.accentGradient)
                }
            }
            
            // App info
            VStack(alignment: .leading, spacing: 3) {
                Text(app.appName)
                    .font(ZKTypography.body)
                    .foregroundColor(ZKColors.textPrimary)
                Text(app.bundleIdentifier)
                    .font(ZKTypography.caption)
                    .foregroundColor(ZKColors.textTertiary)
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
        if let path = app.appPath {
            appIcon = NSWorkspace.shared.icon(forFile: path)
        } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
            appIcon = NSWorkspace.shared.icon(forFile: url.path)
        }
    }
}

// MARK: - App Picker View

struct AppPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AppPickerViewModel()
    @State private var searchText = ""
    let onSelect: (ExcludedApp) -> Void
    
    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return viewModel.apps
        }
        return viewModel.apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient accent
            HStack {
                HStack(spacing: 10) {
                    GradientIcon(systemName: "app.badge.checkmark", size: 20)
                    Text("Chọn ứng dụng")
                        .font(ZKTypography.headline)
                        .foregroundColor(ZKColors.textPrimary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ZKColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(ZKColors.glassBackground)
            
            // Search with modern styling
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(ZKColors.textTertiary)
                TextField("Tìm kiếm...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(ZKTypography.body)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(ZKColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(ZKColors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ZKColors.glassBorder, lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Tabs with modern styling
            Picker("", selection: $viewModel.selectedTab) {
                Text("Tất cả").tag(AppPickerTab.all)
                Text("Đang chạy").tag(AppPickerTab.running)                
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
                .background(ZKColors.glassBorder)
            
            // App list
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Đang tải...")
                        .font(ZKTypography.caption)
                        .foregroundColor(ZKColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredApps.isEmpty {
                VStack(spacing: 12) {
                    GradientIcon(systemName: "app.dashed", size: 40)
                    Text("Không tìm thấy ứng dụng")
                        .font(ZKTypography.body)
                        .foregroundColor(ZKColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredApps) { app in
                            AppPickerRow(app: app) {
                                let excludedApp = ExcludedApp(
                                    bundleIdentifier: app.bundleIdentifier,
                                    appName: app.name,
                                    appPath: app.path
                                )
                                onSelect(excludedApp)
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 480, height: 550)
        .background(
            ZStack {
                Color(hex: "1a1a2e")
                Color.white.opacity(0.02)
            }
        )
        .onAppear {
            viewModel.loadApps()
        }
    }
}

// MARK: - App Picker Row

struct AppPickerRow: View {
    let app: AppInfo
    let onSelect: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon with glass background
            ZStack {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ZKColors.glassBackground)
                        .frame(width: 36, height: 36)
                    Image(systemName: "app.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(ZKColors.accentGradient)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(ZKTypography.body)
                    .foregroundColor(ZKColors.textPrimary)
                Text(app.bundleIdentifier)
                    .font(ZKTypography.caption)
                    .foregroundColor(ZKColors.textTertiary)
            }
            
            Spacer()
            
            // Add button with gradient
            Button(action: { onSelect() }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text("Thêm")
                        .font(ZKTypography.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ZKColors.accentGradient)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? ZKColors.glassBackground : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovered ? ZKColors.glassBorder : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(ZKAnimations.springFast) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - View Models

class ZKExcludedAppsViewModel: ObservableObject {
    // Placeholder for future functionality
}

enum AppPickerTab {
    case running
    case all
}

struct AppInfo: Identifiable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let path: String?
    let icon: NSImage?
    
    init(name: String, bundleIdentifier: String, path: String?, icon: NSImage?) {
        self.id = bundleIdentifier
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.icon = icon
    }
}

class AppPickerViewModel: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var isLoading = false
    @Published var selectedTab: AppPickerTab = .all {
        didSet {
            loadApps()
        }
    }
    
    func loadApps() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let loadedApps: [AppInfo]
            
            switch self?.selectedTab {
            case .running:
                loadedApps = self?.loadRunningApps() ?? []
            case .all:
                loadedApps = self?.loadAllApps() ?? []
            case .none:
                loadedApps = []
            }
            
            DispatchQueue.main.async {
                self?.apps = loadedApps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                self?.isLoading = false
            }
        }
    }
    
    private func loadRunningApps() -> [AppInfo] {
        let runningApps = NSWorkspace.shared.runningApplications
        var apps: [AppInfo] = []
        
        for app in runningApps {
            guard let bundleId = app.bundleIdentifier,
                  let name = app.localizedName,
                  app.activationPolicy == .regular else {
                continue
            }
            
            let icon = app.icon
            let path = app.bundleURL?.path
            
            apps.append(AppInfo(
                name: name,
                bundleIdentifier: bundleId,
                path: path,
                icon: icon
            ))
        }
        
        return apps
    }
    
    private func loadAllApps() -> [AppInfo] {
        var apps: [AppInfo] = []
        let fileManager = FileManager.default
        
        // Search in /Applications and ~/Applications
        let appDirs = [
            "/Applications",
            NSHomeDirectory() + "/Applications"
        ]
        
        for dir in appDirs {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: dir) else {
                continue
            }
            
            for item in contents where item.hasSuffix(".app") {
                let appPath = (dir as NSString).appendingPathComponent(item)
                
                if let bundle = Bundle(path: appPath),
                   let bundleId = bundle.bundleIdentifier {
                    let name = (bundle.infoDictionary?["CFBundleDisplayName"] as? String) ??
                               (bundle.infoDictionary?["CFBundleName"] as? String) ??
                               (item as NSString).deletingPathExtension
                    
                    let icon = NSWorkspace.shared.icon(forFile: appPath)
                    
                    apps.append(AppInfo(
                        name: name,
                        bundleIdentifier: bundleId,
                        path: appPath,
                        icon: icon
                    ))
                }
            }
        }
        
        return apps
    }
}
