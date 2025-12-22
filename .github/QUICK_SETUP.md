# ZendyKey Quick Setup

## Prerequisites

- macOS 10.15 (Catalina) or later
- Xcode 12.0 or later
- Git

## Quick Start

```bash
# Clone
git clone https://github.com/zendy199x/ZendyKey.git
cd ZendyKey

# Build (without code signing for local testing)
ENABLE_CODESIGN=false ./build_release.sh

# Run
open Release/ZendyKey.app
```

## Grant Permissions

1. System Preferences → Security & Privacy → Privacy → Accessibility
2. Add ZendyKey.app
3. Restart ZendyKey

## Test Vietnamese Typing

1. Open any text editor
2. Type `xin chaof` → should produce `xin chào`

## Build Options

| Command | Description |
|---------|-------------|
| `./build_release.sh` | Full build with code signing |
| `ENABLE_CODESIGN=false ./build_release.sh` | Local testing build |
| `ENABLE_NOTARIZE=true ./build_release.sh` | Release with notarization |

## Troubleshooting

**"App is damaged" error:**
```bash
xattr -cr /Applications/ZendyKey.app
```

**Build fails:**
```bash
xcode-select --install
```
