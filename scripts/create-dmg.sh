#!/bin/bash
# create-dmg.sh - Create DMG installer for ZendyKey

set -e

# Configuration
APP_NAME="ZendyKey"
APP_PATH="build/DerivedData/Build/Products/Release/${APP_NAME}.app"
DMG_TEMP="dmg_temp"

# Get version from app bundle
if [ -f "$APP_PATH/Contents/Info.plist" ]; then
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
else
    VERSION="dev"
fi

DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "==> Creating DMG: $DMG_NAME"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at $APP_PATH"
    echo "   Run 'make release' first"
    exit 1
fi

# Clean up previous temp folder
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy app to temp folder
echo "==> Copying app..."
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG
echo "==> Creating DMG..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_NAME"

# Generate checksum
echo "==> Generating checksum..."
shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"

# Clean up
rm -rf "$DMG_TEMP"

echo ""
echo "✅ DMG created: $DMG_NAME"
echo "✅ Checksum: $DMG_NAME.sha256"
