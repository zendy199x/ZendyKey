# ZendyKey

<div align="center">
  <img src="assets/logo.png" alt="ZendyKey Logo" width="128" height="128">
  
  **Bộ gõ tiếng Việt hiện đại cho macOS**
  
  [![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/zendy199x/ZendyKey/releases)
  [![macOS](https://img.shields.io/badge/macOS-12.0+-green.svg)](https://www.apple.com/macos/)
  [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
  [![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
</div>

---

## 📖 Giới thiệu

**ZendyKey** là bộ gõ tiếng Việt hiện đại, được viết hoàn toàn bằng **Swift native** và **SwiftUI**, mang lại hiệu suất vượt trội và giao diện người dùng đẹp mắt.

### ✨ Điểm nổi bật

- ⚡ **Hiệu suất vượt trội** - Swift native, tối ưu hóa cho macOS
- 🎨 **Giao diện hiện đại** - SwiftUI với thiết kế Apple-style
- 🔧 **Ổn định & Không bug** - Code base hiện đại, test kỹ lưỡng
- 🛠️ **Debug Window** - Theo dõi real-time hoạt động bộ gõ
- 🚀 **Smart Switch** - Nhớ ngôn ngữ theo ứng dụng
- ⌨️ **IMKit Mode** - Hỗ trợ Terminal/IDE mượt mà
- 🔒 **Bảo mật** - Chạy local, không thu thập dữ liệu

---

## 🎯 Tính năng

### Kiểu gõ hỗ trợ

| Kiểu gõ | Ví dụ |
|---------|-------|
| **Telex** | tiếng → tiếng |
| **VNI** | tie61ng → tiếng |
| **VIQR** | tie^'ng → tiếng |

### Bảng mã

- Unicode (UTF-8) - Khuyến nghị
- TCVN3 (ABC)
- VNI Windows
- Unicode Compound

### Gõ nhanh (Quick Typing)

**Quick Telex:**
- `cc` → `ch`, `gg` → `gi`, `kk` → `kh`
- `nn` → `ng`, `pp` → `ph`, `qq` → `qu`, `tt` → `th`

**Quick Consonant:**
- Đầu từ: `f` → `ph`, `j` → `gi`, `w` → `qu`
- Cuối từ: `g` → `ng`, `h` → `nh`, `k` → `ch`

### Macro System

- Tạo từ viết tắt tùy chỉnh
- Import/Export danh sách macro
- Tự động viết hoa macro

### Tính năng nâng cao

- **Smart Switch** - Nhớ ngôn ngữ theo app
- **Window Title Rules** - Xử lý đặc biệt cho web apps
- **Kiểm tra chính tả** - Tự động phát hiện lỗi
- **IMKit Mode** - Gõ mượt trong Terminal/IDE

---

## 📥 Cài đặt

### Yêu cầu

- macOS 12.0 (Monterey) trở lên
- Quyền Accessibility

### Cài đặt từ Release

1. Tải `ZendyKey.dmg` từ [Releases](https://github.com/zendy199x/ZendyKey/releases)
2. Kéo ZendyKey.app vào Applications
3. Mở ZendyKey và cấp quyền Accessibility:
   - **System Settings** → **Privacy & Security** → **Accessibility**
   - Bật quyền cho ZendyKey

### Build từ source

```bash
git clone https://github.com/zendy199x/ZendyKey.git
cd ZendyKey
xcodebuild -project ZendyKey.xcodeproj -scheme ZendyKey -configuration Release build
```

---

## 🏗️ Cấu trúc dự án

```
ZendyKey/
├── Shared/                 # Shared components
│   └── ZKAppBehaviorDetector.swift
├── ZendyKey/
│   ├── App/               # Entry point
│   ├── Core/
│   │   ├── Engine/        # Vietnamese input engine
│   │   └── Models/        # Data models
│   ├── EventHandling/     # Keyboard event handling
│   ├── UI/                # SwiftUI views
│   └── Utilities/         # Helper utilities
├── ZendyKeyIM/            # IMKit Input Method bundle
└── ZendyKeyTests/         # Unit tests
```

---

## 🔧 Công nghệ

- **Swift 5.9** - 100% Swift native
- **SwiftUI** - Modern UI framework
- **Input Method Kit** - Native input method
- **Core Graphics** - Event handling
- **Sparkle** - Auto-update framework

---

## 📄 Bundle Identifiers

| Component | Bundle ID |
|-----------|-----------|
| ZendyKey (main) | `com.zendy199x.ZendyKey` |
| ZendyKey IM | `com.zendy199x.ZendyKey.InputMethod` |
| App Group | `group.com.zendy199x.ZendyKey` |

---

## 🙏 Credits

ZendyKey được phát triển dựa trên:
- **OpenKey** - Bộ gõ tiếng Việt mã nguồn mở
- **Unikey** - Bộ gõ tiếng Việt phổ biến

---

## 📄 License

MIT License - Xem [LICENSE](LICENSE) để biết thêm chi tiết.

---

<div align="center">
  Made with ❤️ by zendy199x
  
  ⭐ Nếu bạn thấy hữu ích, hãy cho dự án một star!
</div>
