# Development Guide

> Complete guide for building, testing, and contributing to ZendyKey.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Xcode | 15+ | App Store |
| macOS | 12+ | System requirement |
| Git | 2.30+ | Pre-installed |
| SwiftLint | Latest | `brew install swiftlint` |

---

## Quick Start

```bash
# Clone repository
git clone https://github.com/zendy199x/ZendyKey
cd zendy-key

# Open in Xcode
open ZendyKey.xcodeproj

# Build (Cmd+B) and Run (Cmd+R)
```

---

## Project Structure

```
zendy-key/
│
├── ZendyKey/                    # Main app target
│   ├── App/                     # Entry point
│   │   └── ZendyKeyApp.swift   # App delegate
│   │
│   ├── Core/                    # Engine
│   │   ├── Engine/
│   │   │   ├── ZKEngine.swift        # Main engine (3200+ lines)
│   │   │   ├── ZKWordBuffer.swift    # Word buffer
│   │   │   ├── ZKVietnameseData.swift # Character tables
│   │   │   ├── ZKMacroManager.swift  # Shortcuts
│   │   │   └── ZKInputSourceManager.swift
│   │   │
│   │   └── Models/              # Data models
│   │       └── ZKChar.swift
│   │
│   ├── EventHandling/           # Keyboard hook
│   │   ├── ZKKeyboardHandler.swift
│   │   └── AccessibilityManager.swift
│   │
│   ├── UI/                      # SwiftUI views
│   │   ├── Settings/
│   │   │   ├── ZKSettingsView.swift
│   │   │   └── ZKGeneralSettingsView.swift
│   │   │
│   │   ├── MenuBar/
│   │   │   └── ZKStatusBarManager.swift
│   │   │
│   │   └── Onboarding/
│   │       └── ZKOnboardingView.swift
│   │
│   └── Utilities/               # Helpers
│       └── ZKPreferences.swift
│
├── ZendyKeyIM/                  # IMKit input method (optional)
│
├── ZendyKeyTests/               # Unit tests
│   ├── ZKEngineTests.swift      # Engine tests (1000+ lines)
│   └── ZKKeyCodeToCharacterTests.swift
│
├── docs/                        # Documentation
│   ├── engine-algorithm.md
│   ├── architecture.md
│   └── development.md
│
├── scripts/                     # Build scripts
│   ├── build-release.sh
│   └── create-dmg.sh
│
└── .github/                     # CI/CD
    └── workflows/
        ├── ci.yml
        └── release.yml
```

---

## Building

### Debug Build

```bash
# Using Xcode
# Press Cmd+B or Product → Build

# Using xcodebuild
xcodebuild -scheme ZendyKey -configuration Debug build \
    -destination 'platform=macOS'
```

### Release Build

```bash
xcodebuild -scheme ZendyKey -configuration Release build \
    -derivedDataPath build/DerivedData \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO
```

### Create DMG

```bash
# Build release first
xcodebuild -scheme ZendyKey -configuration Release build \
    -derivedDataPath build/DerivedData

# Create DMG
./scripts/create-dmg.sh
```

---

## Testing

### Run All Tests

```bash
# Using Xcode: Cmd+U

# Using xcodebuild
xcodebuild test -scheme ZendyKey \
    -destination 'platform=macOS' \
    | xcpretty
```

### Run Specific Test

```bash
xcodebuild test -scheme ZendyKey \
    -destination 'platform=macOS' \
    -only-testing:ZendyKeyTests/ZKEngineTests/testTelex_AA_ToCircumflex
```

### Test Categories

| Category | File | Focus |
|----------|------|-------|
| Basic vowels | `ZKEngineTests.swift` | aa→â, oo→ô |
| Tones | `ZKEngineTests.swift` | s,f,r,x,j marks |
| Tone placement | `ZKEngineTests.swift` | Modern/old orthography |
| Full words | `ZKEngineTests.swift` | "việt", "được" |
| VNI input | `ZKEngineTests.swift` | 1-9 modifiers |
| Edge cases | `ZKEngineTests.swift` | Buffer limits |

---

## Debugging

### Console.app

```bash
# Build and run app
open build/DerivedData/Build/Products/Release/ZendyKey.app

# Open Console.app and filter by "ZendyKey"
```

### Xcode Debugging

1. Open `ZendyKey.xcodeproj`
2. Set breakpoints in Swift code
3. Run with debugger (Cmd+R)
4. Inspect variables, step through code

### Common Issues

| Problem | Solution |
|---------|----------|
| "ZendyKey can't be opened" | Run `xattr -cr /Applications/ZendyKey.app` |
| Keyboard hook not working | Check Accessibility permission |
| Build fails | Clean build folder (Cmd+Shift+K) |

---

## Code Style

### Swift Conventions

- **Naming**: camelCase for vars/functions, PascalCase for types
- **Prefix**: `ZK` for all ZendyKey classes
- **Formatting**: Xcode default auto-format

### SwiftLint

```bash
# Run SwiftLint
swiftlint lint

# Auto-fix issues
swiftlint --fix
```

### Commit Messages

Follow conventional commits:

```
feat: add tone repositioning for complex vowels
fix: prevent double tone marks on ươ
docs: update architecture documentation
test: add edge cases for mark removal
refactor: simplify vowel detection logic
```

---

## Troubleshooting

### Build Issues

| Problem | Solution |
|---------|----------|
| "No such module" | Clean build, re-open Xcode |
| Signing error | Disable code signing in build settings |
| Swift version mismatch | Check Xcode version |

### Runtime Issues

| Problem | Solution |
|---------|----------|
| Not typing Vietnamese | Check Accessibility permission |
| Slow response | Check CPU usage, restart app |
| Settings not saving | Check ~/Library/Preferences/ |

---

## Contributing

1. **Fork** the repository
2. **Create branch**: `git checkout -b feat/my-feature`
3. **Make changes** and add tests
4. **Run tests**: Cmd+U in Xcode
5. **Lint**: `swiftlint lint`
6. **Commit**: Follow conventional commits
7. **Push** and create Pull Request

---

## Release Process

1. Update version in `Info.plist`
2. Create git tag: `git tag v1.2.3`
3. Push: `git push origin v1.2.3`
4. GitHub Actions automatically:
   - Runs tests
   - Builds release
   - Creates DMG
   - Publishes release

---

*Last updated: 2025-12-23*

[← Back to Documentation](README.md)
