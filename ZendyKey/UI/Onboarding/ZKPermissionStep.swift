//
//  ZKPermissionStep.swift
//  ZendyKey
//
//  Permission request step for onboarding flow
//

import SwiftUI

// MARK: - Permission Step View

struct ZKPermissionStep: View {
    let hasPermission: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)
                
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                    )
            }
            
            VStack(spacing: 8) {
                Text("Cấp quyền Accessibility")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("ZendyKey cần quyền này để nhận phím từ bàn phím")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            // Steps
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(number: "1", text: "Mở Privacy & Security → Accessibility")
                InstructionRow(number: "2", text: "Tìm và bật công tắc bên cạnh ZendyKey")
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            
            // Permission status with animation
            if hasPermission {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Đã cấp quyền thành công!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Instruction Row Component

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.orange)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
