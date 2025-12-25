# Contributing to ZendyKey

Cảm ơn bạn đã quan tâm đến việc đóng góp cho ZendyKey!

---

## 🚀 Quick Start

```bash
# Clone and setup
git clone https://github.com/zendy199x/ZendyKey
cd zendy-key
make setup

# Build and test
make build
make test
```

---

## 🐛 Báo lỗi / Bug Reports

1. Kiểm tra [Issues](https://github.com/zendy199x/ZendyKey/issues) hiện có
2. Tạo issue mới với thông tin:
   - macOS version
   - ZendyKey version  
   - Input method (Telex/VNI/VIQR)
   - Steps to reproduce

---

## ✨ Đề xuất tính năng

1. Kiểm tra [Issues](https://github.com/zendy199x/ZendyKey/issues)
2. Mô tả rõ:
   - Tính năng mong muốn
   - Use case
   - Giải pháp thay thế (nếu có)

---

## 🔧 Pull Requests

### Workflow

1. **Fork** repository
2. **Clone**: `git clone https://github.com/YOUR-USERNAME/ZendyKey`
3. **Branch**: `git checkout -b feat/your-feature`
4. **Code**: Make changes
5. **Test**: `make test`
6. **Lint**: `make lint`
7. **Commit**: Follow conventional commits
8. **Push**: `git push origin feat/your-feature`
9. **PR**: Create Pull Request

### Commit Messages

```
feat: add new feature
fix: fix bug
docs: update documentation
test: add tests
refactor: refactor code
```

### PR Checklist

- [ ] Tests pass (`make test`)
- [ ] Code linted (`make lint`)
- [ ] Documentation updated (if needed)
- [ ] Tested on macOS 12+

---

## 📁 Project Structure

```
ZendyKey/
├── Core/Engine/     # Vietnamese engine
├── EventHandling/   # Keyboard hook
├── UI/              # SwiftUI views
└── Utilities/       # Helpers
```

---

## 🎨 Code Style

- **Prefix**: All classes use `ZK` prefix
- **Naming**: camelCase for vars, PascalCase for types
- **Format**: Xcode default auto-format
- **Lint**: SwiftLint

---

## 📚 Documentation

- [Engine Algorithm](docs/engine-algorithm.md)
- [Architecture](docs/architecture.md)
- [Development Guide](docs/development.md)

---

## ❓ Questions?

Open a [Discussion](https://github.com/zendy199x/ZendyKey/discussions)!
