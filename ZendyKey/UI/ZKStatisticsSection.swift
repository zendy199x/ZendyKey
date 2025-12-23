//
//  ZKStatisticsSection.swift
//  ZendyKey
//
//  Statistics settings section with premium glassmorphism design
//  Displays typing speed, keystroke counts, and usage analytics
//

import SwiftUI

// MARK: - Statistics Section View

@available(macOS 13.0, *)
struct ZKStatisticsSection: View {
    @ObservedObject var stats = ZKStatisticsManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showResetConfirmation = false
    @State private var showExportSheet = false
    @State private var animateSpeed = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                statsHeader
                
                // Typing Speed Card (Hero section)
                typingSpeedCard
                
                // Today's Statistics
                todayStatsCard
                
                // All-Time Statistics
                allTimeStatsCard
                
                // Top Shortcuts
                if !stats.topShortcuts.isEmpty {
                    topShortcutsCard
                }
                
                // Actions
                actionsCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .overlay {
            if showResetConfirmation {
                ZKResetConfirmationOverlay(
                    colorScheme: colorScheme,
                    onResetToday: {
                        stats.resetTodayStatistics()
                        showResetConfirmation = false
                    },
                    onResetAll: {
                        stats.resetAllStatistics()
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateSpeed = true
            }
        }
    }



    
    // MARK: - Header
    
    private var statsHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 24))
                .foregroundStyle(ZKColors.accentGradient)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Thống kê gõ phím")
                    .font(ZKTypography.title2)
                    .foregroundColor(ZKColors.textPrimary)
                
                if let startDate = formatStartDate() {
                    Text("Từ \(startDate)")
                        .font(ZKTypography.caption)
                        .foregroundColor(ZKColors.textTertiary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Typing Speed Card
    
    private var typingSpeedCard: some View {
        AdaptiveGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    GradientIcon(systemName: "speedometer", size: 16)
                    Text("Tốc độ gõ phím")
                        .font(ZKTypography.headline)
                        .foregroundColor(ZKColors.textPrimary)
                }
                
                HStack(spacing: 32) {
                    // WPM
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(stats.wordsPerMinute))")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "38EF7D"), Color(hex: "11998E")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(animateSpeed ? 1.0 : 0.8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateSpeed)
                            
                            Text("từ/phút")
                                .font(ZKTypography.caption)
                                .foregroundColor(ZKColors.textSecondary)
                        }
                        
                        Text("WPM")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textTertiary)
                    }
                    
                    Divider()
                        .frame(height: 50)
                    
                    // CPM
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(stats.charsPerMinute))")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(animateSpeed ? 1.0 : 0.8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateSpeed)
                            
                            Text("ký tự/phút")
                                .font(ZKTypography.caption)
                                .foregroundColor(ZKColors.textSecondary)
                        }
                        
                        Text("CPM")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    // Total typing time
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(stats.totalTypingMinutes)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(ZKColors.textPrimary)
                        
                        Text("phút đã gõ")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Today Stats Card
    
    private var todayStatsCard: some View {
        AdaptiveGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    GradientIcon(systemName: "calendar", size: 16)
                    Text("Hôm nay")
                        .font(ZKTypography.headline)
                        .foregroundColor(ZKColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(stats.todayTypingMinutes) phút")
                        .font(ZKTypography.caption)
                        .foregroundColor(ZKColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(ZKColors.accent.opacity(0.1))
                        )
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatCell(
                        icon: "keyboard.fill",
                        iconColor: .blue,
                        value: stats.todayKeystrokes,
                        label: "Phím gõ"
                    )
                    
                    StatCell(
                        icon: "textformat",
                        iconColor: .green,
                        value: stats.todayVietnameseChars,
                        label: "Ký tự VN"
                    )
                    
                    StatCell(
                        icon: "text.badge.star",
                        iconColor: .orange,
                        value: stats.todayShortcuts,
                        label: "Gõ tắt"
                    )
                    
                    StatCell(
                        icon: "arrow.uturn.backward",
                        iconColor: .purple,
                        value: stats.todayAutoRestores,
                        label: "Auto-restore"
                    )
                }
            }
        }
    }
    
    // MARK: - All-Time Stats Card
    
    private var allTimeStatsCard: some View {
        AdaptiveGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    GradientIcon(systemName: "clock.arrow.circlepath", size: 16)
                    Text("Tất cả thời gian")
                        .font(ZKTypography.headline)
                        .foregroundColor(ZKColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(stats.totalTypingMinutes) phút")
                        .font(ZKTypography.caption)
                        .foregroundColor(ZKColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(ZKColors.accent.opacity(0.1))
                        )
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatCell(
                        icon: "keyboard.fill",
                        iconColor: .blue,
                        value: stats.totalKeystrokes,
                        label: "Phím gõ"
                    )
                    
                    StatCell(
                        icon: "textformat",
                        iconColor: .green,
                        value: stats.totalVietnameseChars,
                        label: "Ký tự VN"
                    )
                    
                    StatCell(
                        icon: "text.badge.star",
                        iconColor: .orange,
                        value: stats.totalShortcuts,
                        label: "Gõ tắt"
                    )
                    
                    StatCell(
                        icon: "arrow.uturn.backward",
                        iconColor: .purple,
                        value: stats.totalAutoRestores,
                        label: "Auto-restore"
                    )
                }
            }
        }
    }
    
    // MARK: - Top Shortcuts Card
    
    private var topShortcutsCard: some View {
        AdaptiveGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    GradientIcon(systemName: "star.fill", size: 16)
                    Text("Gõ tắt hay dùng")
                        .font(ZKTypography.headline)
                        .foregroundColor(ZKColors.textPrimary)
                }
                
                VStack(spacing: 8) {
                    ForEach(Array(stats.topShortcuts.prefix(5).enumerated()), id: \.element.shortcut) { index, item in
                        HStack {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(ZKColors.textTertiary)
                                .frame(width: 20)
                            
                            Text(item.shortcut)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(ZKColors.textPrimary)
                            
                            Spacer()
                            
                            Text("\(item.count) lần")
                                .font(ZKTypography.caption)
                                .foregroundColor(ZKColors.textSecondary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(ZKColors.glassBackground.opacity(0.5))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        AdaptiveGlassCard(padding: 12) {
            HStack(spacing: 12) {
                // Export button
                Button(action: exportStatistics) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text("Xuất thống kê")
                            .font(ZKTypography.body)
                    }
                    .foregroundColor(ZKColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ZKColors.glassBackground)
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Reset button
                Button(action: { showResetConfirmation = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text("Đặt lại")
                            .font(ZKTypography.body)
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatStartDate() -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: stats.startDate)
    }
    
    private func exportStatistics() {
        let statsText = stats.exportStatistics()
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(statsText, forType: .string)
        
        // Show confirmation (could be enhanced with a toast notification)
        NSSound.beep()
    }
}

// MARK: - Stat Cell Component

struct StatCell: View {
    let icon: String
    let iconColor: Color
    let value: Int
    let label: String
    
    @State private var displayValue: Int = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            
            // Value
            Text(formatNumber(displayValue))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(ZKColors.textPrimary)
            
            // Label
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(ZKColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            animateValue()
        }
        .onChange(of: value) { newValue in
            animateValue()
        }
    }
    
    private func animateValue() {
        // Simple count-up animation
        withAnimation(.easeOut(duration: 0.5)) {
            displayValue = value
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}

// MARK: - Reset Confirmation Overlay

@available(macOS 13.0, *)
struct ZKResetConfirmationOverlay: View {
    let colorScheme: ColorScheme
    let onResetToday: () -> Void
    let onResetAll: () -> Void
    let onCancel: () -> Void
    
    @State private var isHoveringToday = false
    @State private var isHoveringAll = false
    @State private var isHoveringCancel = false
    
    var body: some View {
        ZStack {
            // Backdrop - subtle blur overlay matching app style
            Rectangle()
                .fill(AdaptiveColors.cardBackground(for: colorScheme).opacity(0.9))
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }

            
            // Dialog card using app's glass card style
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    GradientIcon(systemName: "arrow.counterclockwise", size: 28)
                    
                    Text("Đặt lại thống kê?")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AdaptiveColors.textPrimary(for: colorScheme))
                    
                    Text("Chọn loại thống kê muốn đặt lại.\nHành động này không thể hoàn tác.")
                        .font(ZKTypography.body)
                        .foregroundColor(AdaptiveColors.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                
                // Buttons
                VStack(spacing: 10) {
                    // Reset Today
                    Button(action: onResetToday) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                            Text("Chỉ hôm nay")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(ZKColors.accentGradient)
                        )
                        .foregroundColor(.white)
                        .scaleEffect(isHoveringToday ? 1.02 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHoveringToday = $0 }
                    
                    // Reset All
                    Button(action: onResetAll) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                            Text("Tất cả thời gian")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                        .scaleEffect(isHoveringAll ? 1.02 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHoveringAll = $0 }
                    
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
            .frame(width: 280)
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

#if DEBUG
@available(macOS 13.0, *)
struct ZKStatisticsSection_Previews: PreviewProvider {
    static var previews: some View {
        ZKStatisticsSection()
            .frame(width: 600, height: 800)
            .background(Color(hex: "1a1a2e"))
    }
}
#endif

