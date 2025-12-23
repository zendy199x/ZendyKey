//
//  ZKUpdateBadgeView.swift
//  ZendyKey
//
//  Update status badge with spinning animation
//  Inspired by GoNhanh's UpdateBadgeView
//

import SwiftUI

// MARK: - Update Status

enum ZKUpdateStatus: Equatable {
    case idle
    case checking
    case upToDate
    case available(String)  // version string
    case downloading(Double)  // progress 0.0-1.0
    case error(String)
    
    var isChecking: Bool {
        if case .checking = self { return true }
        return false
    }
    
    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }
    
    var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
}

// MARK: - Update Badge View

struct ZKUpdateBadgeView: View {
    let status: ZKUpdateStatus
    let currentVersion: String
    let onCheck: () -> Void
    let onDownload: (() -> Void)?
    
    @State private var rotation: Double = 0
    @State private var hovered = false
    
    init(
        status: ZKUpdateStatus,
        currentVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0",
        onCheck: @escaping () -> Void,
        onDownload: (() -> Void)? = nil
    ) {
        self.status = status
        self.currentVersion = currentVersion
        self.onCheck = onCheck
        self.onDownload = onDownload
    }
    
    private var statusText: String? {
        switch status {
        case .idle: return nil
        case .checking: return "Kiểm tra..."
        case .upToDate: return "Mới nhất"
        case .available(let version): return "v\(version)"
        case .downloading(let progress): return "\(Int(progress * 100))%"
        case .error: return "Lỗi"
        }
    }
    
    private var statusIcon: (name: String, color: Color)? {
        switch status {
        case .upToDate: return ("checkmark.circle.fill", .green)
        case .available: return ("arrow.up.circle.fill", .orange)
        case .error: return ("exclamationmark.triangle.fill", .red)
        case .downloading: return ("arrow.down.circle", .blue)
        default: return nil
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text("v\(currentVersion)")
                .font(.system(size: 11))
            
            if status.isChecking {
                // Spinning animation while checking
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                    .onDisappear {
                        rotation = 0
                    }
            } else if let icon = statusIcon {
                Image(systemName: icon.name)
                    .font(.system(size: 12))
                    .foregroundColor(icon.color)
            }
            
            if let text = statusText {
                Text(text)
                    .font(.system(size: 10))
            }
        }
        .foregroundColor(Color(NSColor.tertiaryLabelColor))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(hovered ? Color(NSColor.controlBackgroundColor).opacity(0.5) : Color.clear)
        )
        .onHover { h in
            hovered = h
            if status.isAvailable {
                if h { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
        }
        .onTapGesture {
            handleTap()
        }
    }
    
    private func handleTap() {
        guard !status.isChecking && !status.isDownloading else { return }
        
        if status.isAvailable {
            onDownload?()
        } else {
            onCheck()
        }
    }
}

// MARK: - Menu Update Item View

struct ZKMenuUpdateItemView: View {
    let status: ZKUpdateStatus
    let onCheck: () -> Void
    let onDownload: (() -> Void)?
    
    @State private var rotation: Double = 0
    
    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            Text(statusTitle)
                .font(.system(size: 13))
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
    }
    
    private var statusTitle: String {
        switch status {
        case .idle: return "Kiểm tra cập nhật"
        case .checking: return "Đang kiểm tra..."
        case .upToDate: return "✓ Đã cập nhật mới nhất"
        case .available(let version): return "⬆ Có bản cập nhật v\(version)"
        case .downloading(let progress): return "⬇ Đang tải... \(Int(progress * 100))%"
        case .error: return "⚠️ Lỗi - thử lại"
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .checking:
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        case .upToDate:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
        case .available:
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange)
        case .downloading:
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 12))
                .foregroundColor(.blue)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(.red)
        default:
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private func handleTap() {
        guard !status.isChecking && !status.isDownloading else { return }
        
        if status.isAvailable {
            onDownload?()
        } else {
            onCheck()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ZKUpdateBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ZKUpdateBadgeView(status: .idle, onCheck: {})
            ZKUpdateBadgeView(status: .checking, onCheck: {})
            ZKUpdateBadgeView(status: .upToDate, onCheck: {})
            ZKUpdateBadgeView(status: .available("2.0.0"), onCheck: {})
            ZKUpdateBadgeView(status: .downloading(0.45), onCheck: {})
            ZKUpdateBadgeView(status: .error("Network error"), onCheck: {})
        }
        .padding()
        .frame(width: 200)
    }
}
#endif
