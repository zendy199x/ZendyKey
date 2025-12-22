# Hướng dẫn Cài đặt ZendyKey

## Yêu cầu hệ thống

- **macOS 12.0** (Monterey) trở lên
- Quyền truy cập **Accessibility**
- Khoảng **20MB** dung lượng ổ đĩa

---

## Cài đặt từ DMG

### Bước 1: Tải về

Tải file `ZendyKey.dmg` mới nhất từ [trang Releases](https://github.com/zendy199x/ZendyKey/releases).

### Bước 2: Cài đặt

1. Mở file `ZendyKey.dmg`
2. Kéo **ZendyKey.app** vào thư mục **Applications**
3. Mở ZendyKey từ Applications

### Bước 3: Cấp quyền Accessibility

ZendyKey cần quyền Accessibility để theo dõi bàn phím:

1. Mở **System Settings** (hoặc System Preferences)
2. Đi tới **Privacy & Security** → **Accessibility**
3. Click 🔒 để mở khóa (nhập mật khẩu admin)
4. Bật ✅ cho **ZendyKey**

> **Lưu ý**: Nếu không thấy ZendyKey trong danh sách, nhấn **+** và chọn từ Applications.

---

## Cài đặt IMKit Mode (Tùy chọn)

IMKit Mode giúp gõ mượt mà hơn trong Terminal và IDE.

### Bước 1: Bật IMKit Mode

1. Mở ZendyKey Settings → **Nâng cao**
2. Bật **IMKit Mode**
3. Click **Cài đặt ZendyKeyIM...**

### Bước 2: Thêm Input Source

1. Mở **System Settings** → **Keyboard** → **Input Sources**
2. Click **+** để thêm
3. Tìm và chọn **ZendyKey Vietnamese**

### Bước 3: Đăng xuất/Đăng nhập

Logout và login lại để hoàn tất cài đặt.

---

## Build từ mã nguồn

### Yêu cầu

- Xcode 15.0+
- macOS 12.0+ SDK
- Command Line Tools

### Build

```bash
# Clone repository
git clone https://github.com/zendy199x/ZendyKey.git
cd ZendyKey

# Build Release
xcodebuild -project ZendyKey.xcodeproj \
           -scheme ZendyKey \
           -configuration Release \
           build

# Hoặc sử dụng build script
./build_release.sh
```

### Output

Build output sẽ nằm ở:
- `build/Release/ZendyKey.app`
- `Release/ZendyKey.dmg` (nếu dùng build script)

---

## Gỡ cài đặt

### Xóa ZendyKey

1. Thoát ZendyKey từ menu bar
2. Kéo `ZendyKey.app` từ Applications vào Trash

### Xóa ZendyKeyIM (nếu có)

1. Xóa từ **System Settings** → **Keyboard** → **Input Sources**
2. Xóa file: `~/Library/Input Methods/ZendyKeyIM.app`

### Xóa preferences (tùy chọn)

```bash
defaults delete com.zendy199x.ZendyKey
rm -rf ~/Library/Application\ Support/ZendyKey
```

---

## Xử lý sự cố

### ZendyKey không hoạt động

1. Kiểm tra quyền Accessibility đã được cấp
2. Thử tắt và bật lại ZendyKey
3. Restart máy tính

### Gõ tiếng Việt bị lỗi trong một số app

1. Thêm Window Title Rule cho app đó
2. Thử bật IMKit Mode
3. Điều chỉnh injection delays trong settings

### Liên hệ hỗ trợ

- **Issues**: [GitHub Issues](https://github.com/zendy199x/ZendyKey/issues)
- **Discussions**: [GitHub Discussions](https://github.com/zendy199x/ZendyKey/discussions)
