//
//  ZKDonationView.swift
//  ZendyKey
//
//  Donation dialog with QR codes for Momo and Bank
//  Modern glassmorphism design
//

import SwiftUI

enum DonationMethod: String, CaseIterable {
    case momo = "Momo"
    case bank = "Bank"
    
    var icon: String {
        switch self {
        case .momo: return "dollarsign.circle"
        case .bank: return "building.columns"
        }
    }
    
    var color: Color {
        switch self {
        case .momo: return Color(hex: "D82D8B")
        case .bank: return Color(hex: "1E88E5")
        }
    }
}

struct ZKDonationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMethod: DonationMethod = .momo
    @State private var isLoadingQR = false
    @State private var showThankYou = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            GradientIcon(systemName: "heart.fill", size: 24)
                            
                            Text("Support ZendyKey")
                                .font(ZKTypography.title2)
                                .foregroundColor(ZKColors.textPrimary)
                        }
                        
                        Button(action: {
                            if let url = URL(string: "https://codetay.com") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text("A product of")
                                    .foregroundColor(ZKColors.textTertiary)
                                Text("Codetay.com")
                                    .foregroundColor(ZKColors.accent)
                            }
                            .font(ZKTypography.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(ZKColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(scale: 1.1, showBackground: false)
                }
                .padding(20)
                
                // Tab selector with animation
                HStack(spacing: 0) {
                    ForEach(DonationMethod.allCases, id: \.self) { method in
                        DonationTabButton(
                            method: method,
                            isSelected: selectedMethod == method,
                            action: {
                                withAnimation(ZKAnimations.spring) {
                                    selectedMethod = method
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // QR Code display
                ScrollView {
                    VStack(spacing: 24) {
                        // QR Code image with animation
                        QRCodeView(method: selectedMethod, isLoading: $isLoadingQR)
                            .frame(width: 280, height: 280)
                            .transition(.scale.combined(with: .opacity))
                            .id(selectedMethod)
                        
                        // Instructions
                        VStack(spacing: 8) {
                            Text(selectedMethod == .momo ? "Quét mã QR bằng ứng dụng Momo" : "Quét mã QR bằng ứng dụng ngân hàng")
                                .font(ZKTypography.headline)
                                .foregroundColor(ZKColors.textPrimary)
                            
                            Text("Mọi đóng góp của bạn đều giúp project phát triển tốt hơn ❤️")
                                .font(ZKTypography.caption)
                                .foregroundColor(ZKColors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        
                        // Copy button
                        Button(action: {
                            // Copy bank info to clipboard
                            let info = selectedMethod == .momo ? "Momo: 0123456789" : "STK: 123456789 - Techcombank"
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(info, forType: .string)
                            
                            withAnimation {
                                showThankYou = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showThankYou = false
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: showThankYou ? "checkmark" : "doc.on.doc")
                                Text(showThankYou ? "Đã copy!" : "Copy thông tin")
                            }
                        }
                        .buttonStyle(ZKButtonStyle(style: .secondary))
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 420, height: 580)
    }
}

struct DonationTabButton: View {
    let method: DonationMethod
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: method.icon)
                    .font(.system(size: 14, weight: .medium))
                Text(method.rawValue)
                    .font(ZKTypography.headline)
            }
            .foregroundColor(isSelected ? .white : ZKColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? method.color : (isHovered ? Color.white.opacity(0.05) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(ZKAnimations.easeOut) {
                isHovered = hovering
            }
        }
    }
}

struct QRCodeView: View {
    let method: DonationMethod
    @Binding var isLoading: Bool
    
    var body: some View {
        ZStack {
            // Load QR code from bundled assets
            let imageName = method == .momo ? "qr_momo" : "qr_bank"
            
            if let nsImage = NSImage(named: imageName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(ZKColors.warningGradient)
                    
                    Text("Không tìm thấy mã QR")
                        .font(ZKTypography.headline)
                        .foregroundColor(ZKColors.textPrimary)
                    
                    Text("Vui lòng liên hệ developer")
                        .font(ZKTypography.caption)
                        .foregroundColor(ZKColors.textTertiary)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(method.color.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ZKDonationView()
}
