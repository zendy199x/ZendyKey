//
//  ZKSection.swift
//  ZendyKey
//
//  Reusable section component with title and box content
//  Used for: Settings sections (KIỂU GÕ, BẢNG MÃ, TÙY CHỌN, etc.)
//

import SwiftUI

// MARK: - ZKSection

struct ZKSection<Content: View>: View {
    let title: String
    var showTitle: Bool = true
    var padding: CGFloat = 16
    var spacing: CGFloat = 12
    let content: Content
    
    init(
        _ title: String,
        showTitle: Bool = true,
        padding: CGFloat = 16,
        spacing: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showTitle = showTitle
        self.padding = padding
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // Title
            if showTitle {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ZKColors.textSecondary)
                    .textCase(.uppercase)
            }
            
            // Content Box
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - ZKSectionBox (Box only, no title)

struct ZKSectionBox<Content: View>: View {
    var padding: CGFloat = 16
    let content: Content
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview("ZKSection") {
    VStack(spacing: 24) {
        ZKSection("Kiểu gõ") {
            Text("Segment picker here")
                .foregroundColor(.white)
            
            Text("a6→â, d9→đ, a8→ă, 1/2/3/4/5→dấu")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        
        ZKSection("Bảng mã") {
            Text("Radio group here")
                .foregroundColor(.white)
        }
        
        ZKSection("Tùy chọn", padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Option 1").foregroundColor(.white)
                Text("Option 2").foregroundColor(.white)
                Text("Option 3").foregroundColor(.white)
            }
        }
        
        // Box only
        ZKSectionBox {
            Text("Box without title")
                .foregroundColor(.white)
        }
    }
    .padding(40)
    .background(Color(hex: "1a1a2e"))
}
