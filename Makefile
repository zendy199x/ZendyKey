# ZendyKey Makefile
# Build automation for ZendyKey Vietnamese input method

.PHONY: all setup build test lint clean install dmg release help

# Default target
all: build

# Show help
help:
	@echo "ZendyKey Build Commands:"
	@echo ""
	@echo "  make setup    - First-time setup (install SwiftLint)"
	@echo "  make build    - Build debug version"
	@echo "  make release  - Build release version"
	@echo "  make test     - Run unit tests"
	@echo "  make lint     - Run SwiftLint"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make install  - Install to /Applications"
	@echo "  make dmg      - Create DMG installer"
	@echo ""

# First-time setup
setup:
	@echo "==> Installing SwiftLint..."
	@brew install swiftlint || true
	@echo "==> Setup complete!"

# Build debug
build:
	@echo "==> Building ZendyKey (Debug)..."
	@xcodebuild -scheme ZendyKey -configuration Debug build \
		-destination 'platform=macOS' \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		-quiet

# Build release
release:
	@echo "==> Building ZendyKey (Release)..."
	@xcodebuild -scheme ZendyKey -configuration Release build \
		-derivedDataPath build/DerivedData \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO
	@echo "==> Build complete: build/DerivedData/Build/Products/Release/ZendyKey.app"

# Run unit tests
test:
	@echo "==> Running unit tests..."
	@xcodebuild test -scheme ZendyKey \
		-destination 'platform=macOS' \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO 2>&1 | xcpretty --test --color || true

# Run SwiftLint
lint:
	@echo "==> Running SwiftLint..."
	@swiftlint lint --quiet

# Clean build artifacts
clean:
	@echo "==> Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf ~/Library/Developer/Xcode/DerivedData/ZendyKey-*
	@echo "==> Clean complete"

# Install to /Applications
install: release
	@echo "==> Installing to /Applications..."
	@rm -rf /Applications/ZendyKey.app
	@cp -R build/DerivedData/Build/Products/Release/ZendyKey.app /Applications/
	@echo "==> Installed ZendyKey.app to /Applications"

# Create DMG
dmg: release
	@echo "==> Creating DMG..."
	@./scripts/create-dmg.sh
	@echo "==> DMG created"
