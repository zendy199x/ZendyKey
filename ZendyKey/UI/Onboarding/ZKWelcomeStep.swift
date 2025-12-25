//
//  ZKWelcomeStep.swift
//  ZendyKey
//
//  Welcome step for onboarding flow
//

import SwiftUI

// MARK: - Welcome Step View

struct ZKWelcomeStep: View {
    let isAnimating: Bool
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Logo with glow
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                if let logo = NSImage(named: "ZendyKeyLogo") {
                    Image(nsImage: logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: accentColor.opacity(0.5), radius: 20)
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(accentColor)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("ZK")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .scaleEffect(isAnimating ? 1 : 0.8)
            .opacity(isAnimating ? 1 : 0)
            
            VStack(spacing: 8) {
                Text("Chào mừng bạn đến với")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("ZendyKey")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("Bộ gõ tiếng Việt thông minh cho MacOS")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Features
            VStack(spacing: 12) {
                FeatureRow(icon: "keyboard.fill", title: "Telex - VNI - VIQR & Simple Telex", desc: "Hỗ trợ đầy đủ các kiểu gõ", color: accentColor)
                FeatureRow(icon: "sparkles", title: "Thông minh", desc: "Hỗ trợ nhiều tính năng thông minh", color: .orange)
                FeatureRow(icon: "bolt.fill", title: "Siêu nhanh", desc: "Tối ưu hiệu năng cao nhất", color: .green)
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
    }
}
