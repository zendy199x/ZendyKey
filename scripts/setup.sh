#!/bin/bash
# setup.sh - First-time setup for ZendyKey development

set -e

echo "==> ZendyKey Development Setup"
echo ""

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from App Store."
    exit 1
fi

echo "✅ Xcode: $(xcodebuild -version | head -1)"

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
echo "✅ macOS: $MACOS_VERSION"

# Install SwiftLint
echo ""
echo "==> Installing SwiftLint..."
if command -v swiftlint &> /dev/null; then
    echo "✅ SwiftLint already installed: $(swiftlint version)"
else
    if command -v brew &> /dev/null; then
        brew install swiftlint
        echo "✅ SwiftLint installed"
    else
        echo "⚠️  Homebrew not found. Install SwiftLint manually:"
        echo "   brew install swiftlint"
    fi
fi

# Install xcpretty (optional, for prettier test output)
echo ""
echo "==> Installing xcpretty..."
if command -v xcpretty &> /dev/null; then
    echo "✅ xcpretty already installed"
else
    gem install xcpretty || echo "⚠️  Could not install xcpretty (optional)"
fi

echo ""
echo "==> Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Open ZendyKey.xcodeproj in Xcode"
echo "  2. Build: Cmd+B or 'make build'"
echo "  3. Run: Cmd+R"
echo "  4. Test: Cmd+U or 'make test'"
echo ""
