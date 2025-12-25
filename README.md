<h1 align="center">
  <img src="assets/logo.png" alt="ZendyKey Logo" width="128" height="128"><br>
  ZendyKey
</h1>

<p align="center">
  <img src="https://img.shields.io/github/downloads/zendy199x/ZendyKey/total?label=Downloads" />
  <img src="https://img.shields.io/github/contributors/zendy199x/ZendyKey" />
  <img src="https://img.shields.io/github/last-commit/zendy199x/ZendyKey" />
</p>
<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS-000000?logo=apple&logoColor=white" />
  <img src="https://img.shields.io/badge/Swift-5.9-FA7343?logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" />
  <img src="https://github.com/zendy199x/ZendyKey/actions/workflows/ci.yml/badge.svg" alt="CI">
</p>

<p align="center">
  <strong>Bộ gõ tiếng Việt hiện đại, nhanh, ổn định cho macOS.</strong><br>
  Cài là dùng. Không quảng cáo. Không thu thập dữ liệu.
</p>

---

## 📥 Tải về & Cài đặt

### 📦 Tải thủ công

| Nền tảng | Trạng thái | Tải xuống | Hướng dẫn |
|:--------:|:----------:|:---------:|:----------|
| **macOS** | ✅ Sẵn sàng | [📥 Tải ZendyKey.dmg](https://github.com/zendy199x/ZendyKey/releases/latest) | [Xem hướng dẫn](docs/install-macos.md) |

<details>
<summary><strong>⚠️ macOS: App không mở được?</strong></summary>

```bash
# Chạy lệnh này trong Terminal sau khi kéo app vào Applications
xattr -cr /Applications/ZendyKey.app
```

Sau đó: **System Settings → Privacy & Security → Accessibility → Bật ZendyKey**

</details>

---

## ✨ Tính năng

### 🔥 Highlight

- ⚡ **Siêu nhanh** — Swift native, <1ms latency, ~5MB RAM
- 🔤 **Auto-restore tiếng Anh** — Gõ `text` `expect` `user` → tự khôi phục khi nhấn space
- ⎋ **ESC tự khôi phục** — Gõ `user` → `úẻ` → nhấn **ESC** → `user`
- 🧠 **Nhớ ngôn ngữ theo app** — Code trên VS Code (tắt) → Chat (bật)
- 🔍 **Fix lỗi Chrome/Arc** — Tự động sửa dính chữ trong address bar
- 🔧 **Quick Telex** — `cc`→`ch`, `gg`→`gi`, `nn`→`ng`, `kk`→`kh`, `pp`→`ph`
- 🌗 **Dark/Light Mode** — Theo hệ thống hoặc tùy chọn

### 📋 Đầy đủ

- ⌨️ **Telex, VNI & VIQR** — Chọn kiểu gõ quen thuộc
- 🎯 **Đặt dấu chuẩn** — Hiện đại (`hoà`) hoặc cổ điển (`hòa`)
- ✂️ **Gõ tắt (Macro)** — `vn` → `Việt Nam`
- 🔌 **Mọi app** — VS Code, Chrome, Terminal, Notion...
- 🔒 **IMKit Mode** — Hỗ trợ Terminal/IDE mượt mà

### 🛡️ Cam kết "Ba Không"

- 🚫 **Không thu phí** — Miễn phí mãi mãi
- 🚫 **Không quảng cáo** — Không popup, không làm phiền
- 🚫 **Không theo dõi** — Offline 100%, mã nguồn mở

---

## 🔤 Auto-restore tiếng Anh

Khi gõ tiếng Anh bằng Telex, một số chữ cái bị nhận nhầm thành modifier:

| Gõ | macOS Telex | ZendyKey |
|:---|:------------|:---------|
| `text ` | `têt ` ❌ | `text ` ✅ |
| `expect ` | `ễpct ` ❌ | `expect ` ✅ |
| `window ` | `ưindow ` ❌ | `window ` ✅ |
| `user ` | `úẻ ` ❌ | `user ` ✅ |
| `file ` | `file ` ✅ | `file ` ✅ |

### ✅ Patterns được nhận diện

| Pattern | Ví dụ |
|:--------|:------|
| Modifier + phụ âm | `text`, `next`, `expect` |
| W đầu + phụ âm | `window`, `water`, `write` |
| F đầu | `file`, `fix`, `function` |
| Invalid vowel pairs | `search`, `teacher` |

---

## 🎯 So sánh

| Tính năng | ZendyKey | OpenKey | GoNhanh |
|-----------|:--------:|:-------:|:-------:|
| macOS Native | ✅ | ❌ | ✅ |
| Swift/SwiftUI | ✅ | ❌ | ❌ (Rust) |
| Auto-restore English | ✅ | ❌ | ✅ |
| ESC Restore | ✅ | ⚠️ | ✅ |
| Per-App Mode | ✅ | ⚠️ | ✅ |
| **Quick Telex** | ✅ | ❌ | ❌ |
| **IMKit Support** | ✅ | ❌ | ❌ |
| **VIQR Input** | ✅ | ⚠️ | ❌ |
| **Macro Import/Export** | ✅ | ❌ | ⚠️ |
| **Chrome/Arc Fix** | ✅ | ⚠️ | ⚠️ |
| **Pause Key** | ✅ | ❌ | ❌ |
| **Smart Switch** | ✅ | ❌ | ✅ |

---

## ⌨️ Phím tắt

| Phím | Chức năng |
|------|-----------|
| `Ctrl + Shift` | Chuyển VN/EN (mặc định) |
| `ESC` | Khôi phục từ về dạng chưa có dấu |
| `Option` (giữ) | Tạm dừng gõ tiếng Việt |
| `Backspace` | Xóa từng ký tự |

---

## ❓ Câu hỏi thường gặp (FAQ)

<details>
<summary><strong>Làm sao để bật gõ tiếng Việt?</strong></summary>

Sau khi cài đặt, ZendyKey sẽ xuất hiện trong menu bar. Click vào icon và chọn "Bật tiếng Việt" hoặc nhấn `Ctrl + Shift`.

</details>

<details>
<summary><strong>Tại sao ZendyKey không hoạt động trong một số app?</strong></summary>

1. **Kiểm tra quyền Accessibility**: System Settings → Privacy & Security → Accessibility → Bật ZendyKey
2. **Excluded Apps**: Kiểm tra app có trong danh sách loại trừ không (Settings → Excluded Apps)
3. **Restart app**: Thử khởi động lại app đang dùng

</details>

<details>
<summary><strong>Có thể dùng VNI thay vì Telex được không?</strong></summary>

Có! Vào Settings → Input → chọn "VNI" trong phần Input Method. ZendyKey hỗ trợ Telex, VNI, và VIQR.

</details>

<details>
<summary><strong>Làm sao để tạm dừng gõ tiếng Việt?</strong></summary>

Nhấn giữ phím **Option (⌥)** để tạm thời chuyển sang tiếng Anh. Thả ra sẽ tự động quay lại tiếng Việt.

</details>

<details>
<summary><strong>Macro là gì và sử dụng như thế nào?</strong></summary>

Macro giúp bạn gõ tắt. Ví dụ: `vn` → `Việt Nam`. Vào Settings → Macros để thêm/sửa/xóa macro. Bạn cũng có thể import/export macro dạng text file.

</details>

<details>
<summary><strong>ZendyKey có thu thập dữ liệu không?</strong></summary>

**Không.** ZendyKey hoạt động 100% offline, không gửi bất kỳ dữ liệu nào đi. Mã nguồn mở, bạn có thể tự kiểm tra.

</details>

---

## 🔧 Dành cho Developer

### Build & Test

```bash
# Clone
git clone https://github.com/zendy199x/ZendyKey
cd zendy-key

# Setup (first time)
make setup

# Build
make build        # Debug build
make release      # Release build

# Test
make test

# Install
make install      # Copy to /Applications

# Create DMG
make dmg
```

### Tech Stack

| Layer | Công nghệ |
|-------|-----------|
| **Core Engine** | Swift 5.9 |
| **UI** | SwiftUI |
| **Event Hook** | CGEventTap |
| **IMKit** | InputMethodKit |
| **Testing** | XCTest (50+ tests) |
| **CI/CD** | GitHub Actions |

### Tài liệu kỹ thuật

| Tài liệu | Mô tả |
|----------|-------|
| [Engine Algorithm](docs/engine-algorithm.md) | 7-stage pipeline, tone placement |
| [Architecture](docs/architecture.md) | System design, data flow |
| [Validation](docs/validation-algorithm.md) | 5 validation rules |
| [Development](docs/development.md) | Build, test, contribute |
| [Common Issues](docs/common-issues.md) | Troubleshooting |

---

## 🤝 Đóng góp

Chúng tôi luôn chào đón contribution! Xem [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 🙏 Credits

ZendyKey được phát triển dựa trên:
- **OpenKey** — Bộ gõ tiếng Việt mã nguồn mở
- **GoNhanh** — Nguồn cảm hứng cho nhiều tính năng

---

## 📄 License

MIT License — Xem [LICENSE](LICENSE).

---

<div align="center">
  Made with ❤️ by zendy199x
  
  ⭐ Nếu bạn thấy hữu ích, hãy cho dự án một star!
</div>
