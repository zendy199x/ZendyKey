---
description: Run tests for ZendyKey
---

# Testing Workflow

// turbo-all

## Run All Tests
```bash
xcodebuild test -scheme ZendyKey -destination 'platform=macOS'
```

## Build Only (Verify Tests Compile)
```bash
xcodebuild -scheme ZendyKey -configuration Debug build
```

## Run SwiftLint
```bash
swiftlint lint --quiet
```
