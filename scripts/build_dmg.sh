#!/bin/bash

# build-dmg.sh - Create DMG for ZendyKey
# Usage: ./scripts/build-dmg.sh

set -e

# Configuration
APP_NAME="ZendyKey"
VERSION="${VERSION:-1.0.0}"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR="build"
DMG_DIR="${BUILD_DIR}/dmg"
FINAL_DMG="${BUILD_DIR}/${DMG_NAME}.dmg"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🚀 Creating ${APP_NAME} DMG v${VERSION}${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if app exists
APP_PATH=""
if [ -d "${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app" ]; then
    APP_PATH="${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app"
elif [ -d "${BUILD_DIR}/${APP_NAME}.app" ]; then
    APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
elif [ -d "${BUILD_DIR}/Release/${APP_NAME}.app" ]; then
    APP_PATH="${BUILD_DIR}/Release/${APP_NAME}.app"
fi

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ Error: ${APP_NAME}.app not found in build directory${NC}"
    echo -e "${YELLOW}   Please run build_release.sh first${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Found app: ${APP_PATH}${NC}"

# Step 1: Create DMG directory structure
echo -e "${YELLOW}📁 Creating DMG structure...${NC}"
rm -rf "${DMG_DIR}"
mkdir -p "${DMG_DIR}"

# Copy app
cp -R "${APP_PATH}" "${DMG_DIR}/"

# Step 2: Remove quarantine attribute to avoid "prohibited" overlay on icon
echo -e "${YELLOW}🔓 Removing quarantine attribute...${NC}"
xattr -cr "${DMG_DIR}/${APP_NAME}.app" 2>/dev/null || true
echo -e "${GREEN}   ✓ Quarantine removed${NC}"

# Create Applications symlink
ln -s /Applications "${DMG_DIR}/Applications"

# Step 2: Check for existing background
echo -e "${YELLOW}🎨 Setting up DMG background...${NC}"
if [ -f "assets/dmg-background.png" ]; then
    mkdir -p "${DMG_DIR}/.background"
    cp "assets/dmg-background.png" "${DMG_DIR}/.background/background.png"
    echo -e "${GREEN}   ✓ Using existing background${NC}"
elif [ -f "assets/logo/logo.png" ]; then
    mkdir -p "${DMG_DIR}/.background"
    cp "assets/logo/logo.png" "${DMG_DIR}/.background/background.png"
    echo -e "${GREEN}   ✓ Using logo as background${NC}"
else
    echo -e "${BLUE}   ℹ No custom background (optional)${NC}"
fi

# Step 3: Remove old files
echo -e "${YELLOW}💿 Creating DMG...${NC}"
rm -f "${FINAL_DMG}"

# Step 4: Create DMG directly (simple but reliable approach)
hdiutil create -volname "${APP_NAME}" \
               -srcfolder "${DMG_DIR}" \
               -ov -format UDZO \
               "${FINAL_DMG}"

# Cleanup temp folder
rm -rf "${DMG_DIR}"

# Step 5: Calculate checksums
echo -e "${YELLOW}📋 Generating checksums...${NC}"
shasum -a 256 "${FINAL_DMG}" > "${FINAL_DMG}.sha256"

# Done - Display success notification
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ DMG Creation Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${BLUE}📦 DMG File:${NC}     ${FINAL_DMG}"
echo -e "   ${BLUE}📋 Checksum:${NC}     ${FINAL_DMG}.sha256"
echo -e "   ${BLUE}📊 Size:${NC}         $(du -h "${FINAL_DMG}" | cut -f1)"
echo ""

# macOS notification
if command -v osascript &> /dev/null; then
    osascript -e "display notification \"DMG created: ${FINAL_DMG}\" with title \"${APP_NAME} Build Complete\" sound name \"Glass\"" 2>/dev/null || true
fi

echo -e "${YELLOW}📝 To notarize (optional):${NC}"
echo "   xcrun notarytool submit ${FINAL_DMG} --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID --wait"
echo "   xcrun stapler staple ${FINAL_DMG}"
echo ""
