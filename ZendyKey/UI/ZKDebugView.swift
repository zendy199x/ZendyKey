//
//  ZKDebugView.swift
//  ZendyKey
//
//  SwiftUI Debug Window with modern glassmorphism design
//

import SwiftUI

struct ZKDebugView: View {
    @ObservedObject var viewModel: ZKDebugViewModel
    @State private var isHoveredClear = false
    @State private var isHoveredCopy = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "0f0f1a")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Status bar with glassmorphism
                HStack {
                    HStack(spacing: 12) {
                        // Status indicator
                        Circle()
                            .fill(viewModel.isLoggingEnabled ? ZKColors.success : ZKColors.textTertiary)
                            .frame(width: 10, height: 10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.statusText)
                                .font(ZKTypography.headline)
                                .foregroundColor(ZKColors.textPrimary)
                            
                            Text("Log file: ~/ZendyKey_Debug.log")
                                .font(ZKTypography.caption2)
                                .foregroundColor(ZKColors.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    // Quick actions
                    HStack(spacing: 8) {
                        Toggle("", isOn: $viewModel.isLoggingEnabled)
                            .toggleStyle(ZKToggleStyle())
                            .labelsHidden()
                            .onChange(of: viewModel.isLoggingEnabled) { _ in
                                viewModel.toggleLogging()
                            }
                        
                        Text("Logging")
                            .font(ZKTypography.caption)
                            .foregroundColor(ZKColors.textSecondary)
                    }
                }
                .padding(16)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                )
                
                // Input text area
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 8) {
                            GradientIcon(systemName: "keyboard", size: 14)
                            Text("Input Test Area")
                                .font(ZKTypography.caption)
                                .foregroundColor(ZKColors.textTertiary)
                                .textCase(.uppercase)
                        }
                        
                        Spacer()
                        
                        Button(action: { viewModel.readWordBeforeCursor() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "text.cursor")
                                    .font(.system(size: 11))
                                Text("Read Word (⌘⇧R)")
                                    .font(ZKTypography.caption)
                            }
                            .foregroundColor(ZKColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.05))
                        )
                        .hoverEffect(scale: 1.02, showBackground: false)
                    }
                    
                    TextEditor(text: $viewModel.inputText)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundColor(ZKColors.textPrimary)
                        .padding(12)
                        .frame(height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(ZKColors.glassBorder, lineWidth: 1)
                                )
                        )
                }
                .padding(16)
                
                // Debug logs section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 8) {
                            GradientIcon(systemName: "doc.text", size: 14)
                            Text("Debug Logs")
                                .font(ZKTypography.caption)
                                .foregroundColor(ZKColors.textTertiary)
                                .textCase(.uppercase)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 10) {
                            Toggle("Verbose", isOn: $viewModel.isVerboseLogging)
                                .toggleStyle(ZKCheckboxStyle())
                                .font(ZKTypography.caption)
                                .foregroundColor(ZKColors.textSecondary)
                            
                            Button(action: { viewModel.openLogFile() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "folder")
                                        .font(.system(size: 11))
                                    Text("Open")
                                }
                                .font(ZKTypography.caption)
                                .foregroundColor(ZKColors.textSecondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05)))
                            
                            Button(action: { viewModel.clearLogs() }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(ZKColors.textTertiary)
                            }
                            .buttonStyle(.plain)
                            .hoverEffect(scale: 1.1, showBackground: false)
                            
                            Button(action: { viewModel.copyLogs() }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 12))
                                    .foregroundColor(ZKColors.textTertiary)
                            }
                            .buttonStyle(.plain)
                            .hoverEffect(scale: 1.1, showBackground: false)
                        }
                    }
                    
                    ScrollView {
                        ScrollViewReader { proxy in
                            Text(viewModel.logText)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(ZKColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .id("logBottom")
                                .onChange(of: viewModel.logText) { _ in
                                    proxy.scrollTo("logBottom", anchor: .bottom)
                                }
                        }
                        .padding(12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(ZKColors.glassBorder, lineWidth: 1)
                            )
                    )
                }
                .padding(16)
            }
        }
        .frame(width: 850, height: 650)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    ZKDebugView(viewModel: ZKDebugViewModel())
}
