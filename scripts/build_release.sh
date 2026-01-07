#!/bin/bash

# =============================================================================
# ZendyKey Build Script
# =============================================================================
# This script builds, signs, notarizes, and packages ZendyKey for distribution.
# 
# Usage:
#   ./build_release.sh                    # Build only
#   ./build_release.sh --sign             # Build and sign
#   ./build_release.sh --notarize         # Build, sign, and notarize
#   ./build_release.sh --dmg              # Build and create DMG
#   ./build_release.sh --all              # Full release build
#
# Environment Variables (all OPTIONAL - can be set in .env file):
#   APPLE_ID              - Apple ID for notarization
#   APPLE_TEAM_ID         - Apple Developer Team ID
#   APPLE_APP_PASSWORD    - App-specific password for notarization
#   SIGNING_IDENTITY      - Code signing identity
#   SPARKLE_PRIVATE_KEY   - Sparkle EdDSA private key for signing updates
#
# Without any environment variables, the script builds an unsigned app.
# =============================================================================

set -e

# Load .env file if exists (all variables are optional)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Loading environment from .env file..."
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="ZendyKey"
BUNDLE_ID="com.zendy199x.ZendyKey"
IM_BUNDLE_ID="com.zendy199x.inputmethod.ZendyKey"
MIN_MACOS_VERSION="12.0"

# Paths - Go up one level since script is in scripts/ folder
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$PROJECT_DIR/release"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
APP_PATH="$BUILD_DIR/$PROJECT_NAME.app"
DMG_PATH="$RELEASE_DIR/$PROJECT_NAME.dmg"
ASSETS_DIR="$PROJECT_DIR/assets"

# Xcode project/workspace
XCODEPROJ="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
SCHEME="$PROJECT_NAME"

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed"
        exit 1
    fi
}

get_version() {
    # Get version from Info.plist
    /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PROJECT_DIR/$PROJECT_NAME/Info.plist" 2>/dev/null || echo "1.0.0"
}

get_build_number() {
    /usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PROJECT_DIR/$PROJECT_NAME/Info.plist" 2>/dev/null || echo "1"
}

# =============================================================================
# Build Functions
# =============================================================================

clean_build() {
    log_step "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$RELEASE_DIR"
    log_success "Build directory cleaned"
}

build_app() {
    log_step "Building $PROJECT_NAME..."
    
    if [ ! -d "$XCODEPROJ" ]; then
        log_error "Xcode project not found at $XCODEPROJ"
        log_info "Please create the Xcode project first"
        exit 1
    fi
    
    # Default: Build unsigned (no Developer Account needed)
    # User can still sign by setting SIGNING_IDENTITY environment variable
    if [ -n "$SIGNING_IDENTITY" ] && [ "$SIGNING_IDENTITY" != "-" ]; then
        log_info "Using custom signing identity: $SIGNING_IDENTITY"
        log_info "Building with code signing..."
        
        xcodebuild \
            -project "$XCODEPROJ" \
            -scheme "$SCHEME" \
            -configuration Release \
            -derivedDataPath "$BUILD_DIR/DerivedData" \
            MACOSX_DEPLOYMENT_TARGET="$MIN_MACOS_VERSION" \
            CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
            CODE_SIGNING_REQUIRED=YES \
            CODE_SIGNING_ALLOWED=YES \
            build
        
        log_success "Build completed with signing"
    else
        log_info "Building unsigned (no Developer Account required)..."
        log_info "User may need to run: xattr -cr /Applications/ZendyKey.app"
        
        # Build without signing for development/personal use
        xcodebuild \
            -project "$XCODEPROJ" \
            -scheme "$SCHEME" \
            -configuration Release \
            -derivedDataPath "$BUILD_DIR/DerivedData" \
            MACOSX_DEPLOYMENT_TARGET="$MIN_MACOS_VERSION" \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            build
        
        log_success "Build completed (unsigned)"
    fi
    
    # Copy built app to build directory
    local built_app="$BUILD_DIR/DerivedData/Build/Products/Release/$PROJECT_NAME.app"
    if [ -d "$built_app" ]; then
        cp -R "$built_app" "$APP_PATH"
        # Remove quarantine attribute to avoid "prohibited" icon overlay
        xattr -cr "$APP_PATH" 2>/dev/null || true
        log_success "App copied to $APP_PATH"
    else
        log_error "Built app not found at $built_app"
        exit 1
    fi
}



export_app() {
    log_step "Exporting app..."
    
    # Skip if no archive (unsigned build)
    if [ ! -d "$ARCHIVE_PATH" ]; then
        log_info "No archive found (unsigned build), skipping export"
        return
    fi
    
    # Create export options plist
    cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID:-}</string>
</dict>
</plist>
EOF
    
    xcodebuild \
        -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$BUILD_DIR" \
        -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"
    
    log_success "App exported successfully"
}

# =============================================================================
# Code Signing
# =============================================================================

sign_app() {
    log_step "Signing app..."
    
    if [ -z "$SIGNING_IDENTITY" ]; then
        log_warning "SIGNING_IDENTITY not set, skipping signing"
        return
    fi
    
    # Sign the main app
    codesign --force --deep --options runtime \
        --sign "$SIGNING_IDENTITY" \
        --entitlements "$PROJECT_DIR/$PROJECT_NAME/${PROJECT_NAME}Release.entitlements" \
        "$APP_PATH"
    
    log_success "App signed successfully"
}

verify_signing() {
    log_step "Verifying code signature..."
    
    if codesign --verify --deep --strict "$APP_PATH"; then
        log_success "Code signature verified"
    else
        log_error "Code signature verification failed"
        exit 1
    fi
    
    # Show signature details
    codesign -dv --verbose=4 "$APP_PATH" 2>&1 | head -20
}

# =============================================================================
# Notarization
# =============================================================================

notarize_app() {
    log_step "Notarizing app..."
    
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_TEAM_ID" ] || [ -z "$APPLE_APP_PASSWORD" ]; then
        log_warning "Notarization credentials not set, skipping notarization"
        log_info "Set APPLE_ID, APPLE_TEAM_ID, and APPLE_APP_PASSWORD to enable notarization"
        return
    fi
    
    # Create ZIP for notarization
    local zip_path="$BUILD_DIR/$PROJECT_NAME.zip"
    ditto -c -k --keepParent "$APP_PATH" "$zip_path"
    
    # Submit for notarization
    log_info "Submitting for notarization..."
    xcrun notarytool submit "$zip_path" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_PASSWORD" \
        --wait
    
    # Staple the ticket
    log_info "Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"
    
    log_success "Notarization completed successfully"
    
    # Cleanup
    rm -f "$zip_path"
}

# =============================================================================
# DMG Creation
# =============================================================================

create_dmg() {
    log_step "Creating DMG..."
    
    local version=$(get_version)
    
    # Use the dedicated DMG build script if available
    if [ -f "$PROJECT_DIR/scripts/build-dmg.sh" ]; then
        log_info "Using scripts/build-dmg.sh..."
        (cd "$PROJECT_DIR" && VERSION="$version" "$PROJECT_DIR/scripts/build-dmg.sh")
        
        local dmg_name="${PROJECT_NAME}-${version}.dmg"
        DMG_PATH="$BUILD_DIR/$dmg_name"
        
        # Copy to release folder
        if [ -f "$DMG_PATH" ]; then
            mkdir -p "$RELEASE_DIR"
            cp "$DMG_PATH" "$RELEASE_DIR/$dmg_name"
            cp "$DMG_PATH" "$RELEASE_DIR/$PROJECT_NAME-latest.dmg"
        fi
        return
    fi
    
    # Fallback: simple DMG creation
    local dmg_name="${PROJECT_NAME}-${version}.dmg"
    local dmg_path="$RELEASE_DIR/$dmg_name"
    
    # Remove existing DMG
    rm -f "$dmg_path"
    
    # Create temporary folder for DMG contents
    local dmg_temp="$BUILD_DIR/dmg_temp"
    rm -rf "$dmg_temp"
    mkdir -p "$dmg_temp"
    
    # Copy app
    cp -R "$APP_PATH" "$dmg_temp/"
    
    # Create Applications symlink
    ln -s /Applications "$dmg_temp/Applications"
    
    # Copy background image if exists
    if [ -f "$ASSETS_DIR/dmg_background.png" ]; then
        mkdir -p "$dmg_temp/.background"
        cp "$ASSETS_DIR/dmg_background.png" "$dmg_temp/.background/background.png"
    fi
    
    # Create DMG
    hdiutil create -volname "$PROJECT_NAME" \
        -srcfolder "$dmg_temp" \
        -ov -format UDZO \
        "$dmg_path"
    
    log_success "DMG created: $dmg_path"
    
    # Cleanup
    rm -rf "$dmg_temp"
    
    # Copy to latest
    cp "$dmg_path" "$RELEASE_DIR/$PROJECT_NAME-latest.dmg"
    
    DMG_PATH="$dmg_path"
}

# =============================================================================
# Build ZKIMMain (Input Method) - Optional
# =============================================================================

build_input_method() {
    # Input Method is optional - silently skip if not configured
    local im_scheme="ZendyKeyIM"
    
    # Check if ZendyKeyIM target exists in project
    if ! xcodebuild -list -project "$XCODEPROJ" 2>/dev/null | grep -q "$im_scheme"; then
        # Silently skip - IM target not configured
        return
    fi
    
    log_step "Building ZendyKeyIM (Input Method)..."
    
    xcodebuild \
        -project "$XCODEPROJ" \
        -scheme "$im_scheme" \
        -configuration Release \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        MACOSX_DEPLOYMENT_TARGET="$MIN_MACOS_VERSION" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        build
    
    # Copy built IM app to build directory
    local built_im="$BUILD_DIR/DerivedData/Build/Products/Release/ZendyKeyIM.app"
    if [ -d "$built_im" ]; then
        cp -R "$built_im" "$BUILD_DIR/ZendyKeyIM.app"
        xattr -cr "$BUILD_DIR/ZendyKeyIM.app" 2>/dev/null || true
        log_success "ZendyKeyIM.app copied to $BUILD_DIR"
    fi
    
    log_success "ZendyKeyIM built successfully"
}

# =============================================================================
# Generate Appcast (Sparkle)
# =============================================================================

generate_appcast() {
    log_step "Generating Sparkle appcast..."
    
    local version=$(get_version)
    local build=$(get_build_number)
    local dmg_name="${PROJECT_NAME}-${version}.dmg"
    local dmg_path="$RELEASE_DIR/$dmg_name"
    
    if [ ! -f "$dmg_path" ]; then
        log_warning "DMG not found, skipping appcast generation"
        return
    fi
    
    # Get file size
    local file_size=$(stat -f%z "$dmg_path")
    
    # Get current date in RFC 2822 format
    local pub_date=$(date -R)
    
    # Generate appcast.xml
    cat > "$RELEASE_DIR/appcast.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>$PROJECT_NAME Updates</title>
    <link>https://github.com/zendy199x/ZendyKey/releases</link>
    <description>$PROJECT_NAME release updates</description>
    <language>en</language>
    <item>
      <title>Version $version</title>
      <pubDate>$pub_date</pubDate>
      <sparkle:version>$build</sparkle:version>
      <sparkle:shortVersionString>$version</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MIN_MACOS_VERSION</sparkle:minimumSystemVersion>
      <enclosure 
        url="https://github.com/zendy199x/ZendyKey/releases/download/v$version/$dmg_name"
        length="$file_size"
        type="application/octet-stream"
      />
    </item>
  </channel>
</rss>
EOF
    
    log_success "Appcast generated: $RELEASE_DIR/appcast.xml"
}

# =============================================================================
# Main
# =============================================================================

main() {
    log_step "🚀 ZendyKey Build Script"
    log_info "Version: $(get_version)"
    log_info "Build: $(get_build_number)"
    
    # Check dependencies
    check_command xcodebuild
    check_command codesign
    check_command hdiutil
    
    # Parse arguments
    local do_sign=false
    local do_notarize=false
    local do_dmg=false
    local do_all=false
    
    for arg in "$@"; do
        case $arg in
            --sign)
                do_sign=true
                ;;
            --notarize)
                do_sign=true
                do_notarize=true
                ;;
            --dmg)
                do_dmg=true
                ;;
            --all)
                do_all=true
                do_sign=true
                do_notarize=true
                do_dmg=true
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --sign       Sign the app"
                echo "  --notarize   Sign and notarize the app"
                echo "  --dmg        Create DMG"
                echo "  --all        Full release build"
                echo "  --help       Show this help"
                exit 0
                ;;
        esac
    done
    
    # Build process
    clean_build
    build_app
    export_app
    
    if $do_sign; then
        sign_app
        verify_signing
    fi
    
    if $do_notarize; then
        notarize_app
    fi
    
    build_input_method
    
    # Always create DMG when running without flags, or when --dmg/--all is specified
    if $do_dmg || [ $# -eq 0 ]; then
        create_dmg
        generate_appcast
    fi
    
    # Summary
    log_step "✅ Build Complete!"
    log_info "App: $APP_PATH"
    
    if [ -n "$DMG_PATH" ] && [ -f "$DMG_PATH" ]; then
        log_info "DMG: $DMG_PATH"
        log_info "Size: $(du -h "$DMG_PATH" | cut -f1)"
    fi
    
    log_success "Build finished successfully!"
    
    # macOS notification
    if command -v osascript &> /dev/null; then
        local notify_msg="Build complete!"
        if [ -n "$DMG_PATH" ] && [ -f "$DMG_PATH" ]; then
            notify_msg="DMG created: $(basename "$DMG_PATH")"
        fi
        osascript -e "display notification \"$notify_msg\" with title \"$PROJECT_NAME Build\" sound name \"Glass\"" 2>/dev/null || true
    fi
}

# Run main
main "$@"
