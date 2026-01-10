#!/bin/bash
# =============================================================================
# ZendyKey DMG Creator
# =============================================================================
# Create beautiful DMG installer for ZendyKey with custom layout
#
# Usage:
#   ./create-dmg.sh                              # Use default app path
#   ./create-dmg.sh /path/to/ZendyKey.app        # Use custom app path
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Configuration
APP_NAME="ZendyKey"
VOL_NAME="ZendyKey"
DMG_RESOURCES="$PROJECT_ROOT/assets/dmg"

# Window dimensions and positions
WINDOW_WIDTH=540
WINDOW_HEIGHT=380
ICON_SIZE=100
APP_X=135
APP_Y=175
APPS_X=405
APPS_Y=175

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Get app path from argument or default
APP_PATH="${1:-$PROJECT_ROOT/build/DerivedData/Build/Products/Release/${APP_NAME}.app}"

if [ ! -d "$APP_PATH" ]; then
    log_error "App not found at: $APP_PATH"
    echo ""
    echo "Usage: $0 [path/to/ZendyKey.app]"
    echo ""
    echo "Build the app first:"
    echo "  ./scripts/build_release.sh"
    exit 1
fi

# Get version from app bundle
if [ -f "$APP_PATH/Contents/Info.plist" ]; then
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "1.0.0")
else
    VERSION="${VERSION:-1.0.0}"
fi

# Output paths
BUILD_DIR="$PROJECT_ROOT/build"
RELEASE_DIR="$PROJECT_ROOT/release"
DMG_TEMP="$BUILD_DIR/${APP_NAME}_temp.dmg"
DMG_FINAL="$RELEASE_DIR/${APP_NAME}-${VERSION}.dmg"

mkdir -p "$BUILD_DIR" "$RELEASE_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📦 Creating ZendyKey DMG Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "App: $APP_PATH"
log_info "Version: $VERSION"
echo ""

# Clean up existing DMG
rm -f "$DMG_TEMP" "$DMG_FINAL"

# Create staging directory
STAGING_DIR=$(mktemp -d)
trap "rm -rf $STAGING_DIR" EXIT

log_info "Staging directory: $STAGING_DIR"

# Copy app to staging
log_info "Copying app..."
cp -R "$APP_PATH" "$STAGING_DIR/"

# Remove quarantine attribute
xattr -cr "$STAGING_DIR/${APP_NAME}.app" 2>/dev/null || true

# Create Applications symlink
ln -s /Applications "$STAGING_DIR/Applications"

# Copy background if exists
BACKGROUND_FILE=""
if [ -f "$DMG_RESOURCES/background.tiff" ]; then
    mkdir -p "$STAGING_DIR/.background"
    cp "$DMG_RESOURCES/background.tiff" "$STAGING_DIR/.background/background.tiff"
    BACKGROUND_FILE="background.tiff"
elif [ -f "$DMG_RESOURCES/background.png" ]; then
    mkdir -p "$STAGING_DIR/.background"
    cp "$DMG_RESOURCES/background.png" "$STAGING_DIR/.background/background.png"
    BACKGROUND_FILE="background.png"
else
    log_warning "No background image found in $DMG_RESOURCES"
    log_info "Creating DMG without custom background"
fi

# Calculate size needed (app size + 50MB buffer)
APP_SIZE=$(du -sm "$APP_PATH" | cut -f1)
DMG_SIZE=$((APP_SIZE + 50))
log_info "DMG size: ${DMG_SIZE}MB"

# Create temporary DMG (read-write)
log_info "Creating temporary DMG..."
hdiutil create -srcfolder "$STAGING_DIR" \
    -volname "$VOL_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${DMG_SIZE}m \
    "$DMG_TEMP"

# Mount the DMG
log_info "Mounting DMG..."
MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | grep "/Volumes/$VOL_NAME" | awk '{print $3}')

if [ -z "$MOUNT_DIR" ]; then
    MOUNT_DIR="/Volumes/$VOL_NAME"
fi

log_info "Mounted at: $MOUNT_DIR"

# Wait for mount
sleep 2

# Apply AppleScript to customize the DMG window
log_info "Customizing DMG appearance..."

if [ -n "$BACKGROUND_FILE" ]; then
    BACKGROUND_CLAUSE="set background picture of viewOptions to file \".background:$BACKGROUND_FILE\""
else
    BACKGROUND_CLAUSE=""
fi

osascript <<EOF
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, $((100 + WINDOW_WIDTH)), $((100 + WINDOW_HEIGHT))}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to $ICON_SIZE
        $BACKGROUND_CLAUSE
        set position of item "${APP_NAME}.app" of container window to {$APP_X, $APP_Y}
        set position of item "Applications" of container window to {$APPS_X, $APPS_Y}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Sync and unmount
log_info "Finalizing..."
sync
sleep 3
hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || hdiutil detach "$MOUNT_DIR" -force 2>/dev/null || true
sleep 2

# Convert to compressed DMG
log_info "Compressing DMG..."
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FINAL"

# Clean up temp DMG
rm -f "$DMG_TEMP"

# Generate checksum
log_info "Generating checksum..."
shasum -a 256 "$DMG_FINAL" > "${DMG_FINAL}.sha256"

# Also create a 'latest' copy
cp "$DMG_FINAL" "$RELEASE_DIR/${APP_NAME}-latest.dmg"

# Get final size
FINAL_SIZE=$(du -h "$DMG_FINAL" | cut -f1)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "DMG created successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Output: $DMG_FINAL"
log_info "Size: $FINAL_SIZE"
log_info "Checksum: ${DMG_FINAL}.sha256"
echo ""
echo "To test the DMG:"
echo "  open $DMG_FINAL"
echo ""
