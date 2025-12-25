# Cài đặt ZendyKey trên macOS

## Yêu cầu hệ thống

- macOS 12.0 (Monterey) trở lên
- Chip Intel hoặc Apple Silicon (M1/M2/M3)
- Khoảng 20MB dung lượng

## Cài đặt từ DMG

### Bước 1: Tải về
Tải file `ZendyKey-x.x.x.dmg` từ [Releases](https://github.com/zendy199x/ZendyKey/releases/latest).

### Bước 2: Cài đặt
1. Mở file DMG vừa tải
2. Kéo `ZendyKey.app` vào thư mục `Applications`
3. Đóng cửa sổ DMG

### Bước 3: Cấp quyền Accessibility

> ⚠️ **Bắt buộc**: ZendyKey cần quyền Accessibility để hoạt động.

1. Mở **System Settings** (System Preferences trên macOS cũ)
2. Vào **Privacy & Security** → **Accessibility**
3. Click 🔒 để mở khóa (nếu cần)
4. Bật công tắc bên cạnh **ZendyKey**

### Bước 4: Khởi chạy
- ZendyKey sẽ xuất hiện trên menu bar
- Click icon để truy cập settings

## ⚠️ Xử lý lỗi "App không thể mở"

Nếu gặp lỗi **"ZendyKey cannot be opened because it is from an unidentified developer"**:

```bash
# Mở Terminal và chạy:
xattr -cr /Applications/ZendyKey.app
```

Sau đó thử mở lại ZendyKey.

## Build từ Source

```bash
# Clone repository
git clone https://github.com/zendy199x/ZendyKey.git
cd ZendyKey

# Build
xcodebuild -scheme ZendyKey -configuration Release build

# Hoặc dùng script
./scripts/build_release.sh --dmg
```

## Gỡ cài đặt

1. Đóng ZendyKey từ menu bar → Quit
2. Kéo `ZendyKey.app` từ Applications vào Trash
3. (Tùy chọn) Xóa preferences:
   ```bash
   defaults delete com.zendy199x.ZendyKey
   ```

---

[← Quay lại Documentation](README.md)
