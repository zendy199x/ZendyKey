//
//  ZKMenuBarHeaderView.swift
//  ZendyKey
//
//  Menu bar header view with logo, flag badge, version and status info
//

import SwiftUI

/// Menu bar header view - logo with flag badge, app name with version, and current settings
struct ZKMenuBarHeaderView: View {
    @Binding var isVietnameseEnabled: Bool
    let inputMethodName: String
    let codeTableName: String
    let hotkeyDisplay: String
    
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Logo with flag badge
            logoSection
            
            // App info
            infoSection
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 260, height: 60)
    }
    
    // MARK: - Logo Section with Flag Badge
    
    private var logoSection: some View {
        ZStack(alignment: .topTrailing) {
            // Logo
            Group {
                if let logo = NSImage(named: "ZendyKeyLogo") {
                    Image(nsImage: logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ZKColors.accentGradient)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("ZK")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        )
                }
            }
            
            // Flag badge - centered exactly on the top-right corner of logo
            Text(isVietnameseEnabled ? "🇻🇳" : "🇬🇧")
                .font(.system(size: 18))
                .offset(x: 12, y: -10)
        }
        .frame(width: 56, height: 46)
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            // App name with version
            HStack(spacing: 6) {
                Text("ZendyKey")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("v\(version)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Current status - input method and code table, or "Đã tắt"
            if isVietnameseEnabled {
                Text("\(inputMethodName) · \(codeTableName)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Đã tắt")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#if DEBUG
struct ZKMenuBarHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ZKMenuBarHeaderView(
                isVietnameseEnabled: .constant(true),
                inputMethodName: "Telex",
                codeTableName: "Unicode",
                hotkeyDisplay: "⇧⌘V"
            )
            
            ZKMenuBarHeaderView(
                isVietnameseEnabled: .constant(false),
                inputMethodName: "VNI",
                codeTableName: "TCVN3",
                hotkeyDisplay: "⇧⌘V"
            )
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}
#endif
