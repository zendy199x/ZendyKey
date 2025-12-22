# QWERTZ Keyboard Layout Support

ZendyKey fully supports QWERTZ keyboard layouts commonly used in German-speaking countries.

## Overview

The QWERTZ layout differs from QWERTY primarily in the positions of Y and Z keys. ZendyKey handles this by using virtual key codes rather than character mappings, ensuring correct behavior regardless of physical keyboard layout.

## How It Works

1. **Virtual Key Codes**: ZendyKey uses macOS virtual key codes (e.g., `kVK_ANSI_Y = 0x10`) to identify keys
2. **Layout Detection**: The system automatically detects the current keyboard layout
3. **Character Mapping**: `charactersIgnoringModifiers` is used to get the actual character for the layout

## Supported Layouts

- German (QWERTZ)
- Swiss German (QWERTZ)
- Austrian (QWERTZ)  
- Czech (QWERTZ)
- Slovenian (QWERTZ)
- Hungarian (QWERTZ)

## Vietnamese Input Methods

All Vietnamese input methods (Telex, VNI, VIQR) work correctly on QWERTZ:

| Method | Example | Result |
|--------|---------|--------|
| Telex | `xin chaof` | xin chào |
| VNI | `xin cha2o` | xin chào |
| VIQR | `xin cha\`o` | xin chào |

## Configuration

No special configuration is required. ZendyKey automatically adapts to your keyboard layout.

## Troubleshooting

If you experience issues with QWERTZ:

1. Ensure your macOS keyboard settings are correct
2. Try switching input methods in System Settings
3. Check that ZendyKey has Accessibility permissions
4. File an issue on GitHub if problems persist

## Technical Details

The key handling code in `ZKKeyboardEventHandler.swift` uses:

```swift
// Get character based on current layout, not physical key
guard let characters = event.charactersIgnoringModifiers else { return }
```

This ensures the correct character is detected regardless of keyboard layout.
