#!/bin/bash

# ZendyKey Notarization Script
# This script handles notarization of the DMG for distribution

set -e

APP_NAME="ZendyKey"
DMG_PATH="$1"

if [ -z "$DMG_PATH" ]; then
    echo "Usage: ./notarize.sh <path-to-dmg>"
    exit 1
fi

echo "=== ZendyKey Notarization Script ==="
echo "DMG: $DMG_PATH"

# Check for required environment variables
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_PASSWORD" ] || [ -z "$APPLE_TEAM_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Please set: APPLE_ID, APPLE_APP_PASSWORD, APPLE_TEAM_ID"
    exit 1
fi

# Submit for notarization
echo "Submitting for notarization..."
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait

# Staple the notarization ticket
echo "Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo "=== Notarization Complete ==="
echo "DMG is now ready for distribution: $DMG_PATH"
