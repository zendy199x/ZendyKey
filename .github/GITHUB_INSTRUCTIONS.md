# GitHub Instructions for ZendyKey

## Quick Start

### Prerequisites
- macOS 10.15 Catalina or later
- Xcode 14 or later
- Git

### Clone and Build

```bash
# Clone the repository
git clone https://github.com/zendy199x/ZendyKey.git
cd ZendyKey

# Open in Xcode
open ZendyKey.xcodeproj
```

### First Time Setup

1. **Open Xcode** and select signing team in Project Navigator
2. **Build** the project (⌘+B)
3. **Run** the app (⌘+R)
4. **Grant permissions** when prompted:
   - Accessibility: System Preferences → Security & Privacy → Privacy → Accessibility
   - Input Monitoring: System Preferences → Security & Privacy → Privacy → Input Monitoring

---

## Build Configurations

### Debug Build
```bash
xcodebuild -project ZendyKey.xcodeproj \
  -scheme ZendyKey \
  -configuration Debug \
  build
```

### Release Build
```bash
xcodebuild -project ZendyKey.xcodeproj \
  -scheme ZendyKey \
  -configuration Release \
  build
```

### Build DMG
```bash
./build_release.sh
```

---

## Testing

### Run Unit Tests
```bash
xcodebuild test \
  -project ZendyKey.xcodeproj \
  -scheme ZendyKey \
  -destination 'platform=macOS'
```

### Run Specific Test
```bash
xcodebuild test \
  -project ZendyKey.xcodeproj \
  -scheme ZendyKey \
  -only-testing:ZendyKeyTests/ZKEngineTests
```

---

## Project Structure

```
ZendyKey/
├── ZendyKey/                    # Main application target
│   ├── App/
│   │   ├── ZendyKeyApp.swift    # App entry point
│   │   └── ZKAppDelegate.swift  # App lifecycle
│   ├── Core/
│   │   ├── Engine/              # Vietnamese typing engine
│   │   │   ├── ZKEngine.swift   # Main engine (130KB)
│   │   │   ├── ZKWordBuffer.swift
│   │   │   └── ...
│   │   └── Models/              # Data models
│   ├── EventHandling/           # Keyboard events
│   ├── UI/                      # SwiftUI views
│   ├── Utilities/               # Helper classes
│   └── InputMethod/             # IMKit integration
├── ZKIMMain/                  # Input Method bundle (optional)
├── ZendyKeyTests/               # Unit tests
├── .github/                     # GitHub workflows
└── build_release.sh             # Release script
```

---

## GitHub Workflows

### CI/CD Pipeline
- **build.yml** - Builds on every push/PR
- **update-appcast.yml** - Updates Sparkle appcast on release

### Manual Release
1. Tag a new version: `git tag v1.0.0`
2. Push tags: `git push origin --tags`
3. GitHub Action will automatically build and create release

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

### Branch Naming
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation
- `refactor/` - Code refactoring

### Commit Messages
```
type(scope): description

Examples:
feat(engine): add VIQR support
fix(ui): resolve settings crash
docs(readme): update installation guide
```

---

## Troubleshooting

### Build Errors

**"No signing identity found"**
- Open project settings → Signing & Capabilities
- Select your development team

**"Module not found"**
- Clean build folder: ⌘+Shift+K
- Re-build: ⌘+B

### Runtime Issues

**"ZendyKey wants to use accessibility features"**
- Grant permission in System Preferences → Privacy → Accessibility

**Typing not working**
- Check if ZendyKey is enabled in menu bar
- Verify accessibility permissions
- Restart the application

---

## Bundle Identifiers

| Target | Bundle ID |
|--------|-----------|
| ZendyKey | `com.zendy199x.ZendyKey` |
| ZKIMMain | `com.zendy199x.ZendyKey.InputMethod` |

---

## License

MIT License - see [LICENSE](../LICENSE)
