---
description: Build and release ZendyKey
---

# Build & Release Workflow

// turbo-all

## Debug Build
```bash
xcodebuild -scheme ZendyKey -configuration Debug build
```

## Release Build
```bash
xcodebuild -scheme ZendyKey -configuration Release build
```

## Create DMG
```bash
./scripts/build_release.sh --dmg
```

## Clean Build
```bash
xcodebuild clean -scheme ZendyKey
rm -rf build/
```
