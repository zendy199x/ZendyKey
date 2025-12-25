# System Architecture

> Complete system architecture for ZendyKey Vietnamese input method.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        ZendyKey App                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              SwiftUI Menu Bar                         │   │
│  │  • Input method selector (Telex/VNI/VIQR)            │   │
│  │  • Enable/disable toggle                              │   │
│  │  • Settings, About, Update                            │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────▼───────────────────────────────┐   │
│  │           CGEventTap Keyboard Hook                    │   │
│  │  • Intercepts keyDown events globally                 │   │
│  │  • Smart text replacement (backspace + insert)        │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────▼───────────────────────────────┐   │
│  │                 ZKEngine                              │   │
│  │  • 7-stage processing pipeline                        │   │
│  │  • Validation-first approach                          │   │
│  │  • Auto-restore English detection                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
└──────────────────────────────────────┬──────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────┐
│                     macOS System                            │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  CGEvent Tap │  │ Accessibility│  │   IMKit      │       │
│  │  (Key Hook)  │  │  API         │  │ (Optional)   │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Components

### Core Layer

| Component | File | Purpose |
|-----------|------|---------|
| `ZKEngine` | `ZKEngine.swift` | Main Vietnamese processing engine |
| `ZKWordBuffer` | `ZKWordBuffer.swift` | Word buffer management |
| `ZKVietnameseData` | `ZKVietnameseData.swift` | Character tables, key codes |
| `ZKInputProcessor` | `ZKInputProcessor.swift` | Input method routing |

### Event Handling Layer

| Component | File | Purpose |
|-----------|------|---------|
| `ZKKeyboardHandler` | `ZKKeyboardHandler.swift` | CGEvent tap, key capture |
| `ZKEventTapManager` | `ZKEventTapManager.swift` | Event tap lifecycle |
| `AccessibilityManager` | `AccessibilityManager.swift` | Permission management |

### UI Layer

| Component | File | Purpose |
|-----------|------|---------|
| `ZKSettingsView` | `ZKSettingsView.swift` | Main settings SwiftUI view |
| `ZKStatusBarManager` | `ZKStatusBarManager.swift` | Menu bar icon and popover |
| `ZKOnboardingView` | `ZKOnboardingView.swift` | First-launch onboarding |
| `ZKOnScreenIndicator` | `ZKOnScreenIndicator.swift` | Floating mode indicator |

### Managers

| Component | File | Purpose |
|-----------|------|---------|
| `ZKPerAppModeManager` | `ZKPerAppModeManager.swift` | Per-app language memory |
| `ZKSoundManager` | `ZKSoundManager.swift` | Toggle sounds |
| `ZKMacroManager` | `ZKMacroManager.swift` | Macro/shortcut system |
| `ZKInputSourceManager` | `ZKInputSourceManager.swift` | System input source detection |

---

## Data Flow: Keystroke to Output

### Example: Typing "á" in Telex

```
User types: [a] then [s]

Step 1: Key 'a' pressed
  ├─ CGEventTap captures keyDown
  ├─ ZKKeyboardHandler receives event
  ├─ ZKEngine.handleKeyEvent() called
  │  ├─ Push 'a' to buffer
  │  └─ Return HookState(code: DoNothing)
  ├─ Let 'a' pass through to app
  └─ Output: User sees 'a' typed

Step 2: Key 's' pressed (sắc mark in Telex)
  ├─ CGEventTap captures keyDown
  ├─ ZKKeyboardHandler receives event
  ├─ ZKEngine.handleKeyEvent() called
  │  ├─ Detect 's' = sắc modifier
  │  ├─ Validate: "a" + sắc → valid
  │  ├─ Transform: 'a' → 'á'
  │  └─ Return HookState(code: Process,
  │       backspace: 1, newChars: ['á'])
  ├─ Send 1 backspace (delete 'a')
  ├─ Send 'á' via Unicode event
  ├─ Consume 's' keystroke
  └─ Output: User sees 'á'

Result: "á" displayed instead of "as"
Latency: ~300-500μs total
```

---

## Text Replacement Strategies

### Method 1: Backspace (Default)

```
1. Send: BS BS ... BS (backspace count times)
      ↓ (0.5ms delay)
2. Send: Unicode input event with output chars
```

**Pros:** Fast, minimal flicker  
**Cons:** Issues with autocomplete fields

### Method 2: Selection (for autocomplete apps)

```
1. Send: Shift+Left (select chars)
      ↓
2. Send: Unicode input event (replaces selection)
```

**Pros:** Works with autocomplete  
**Cons:** Slower, visible selection

---

## App Compatibility

### Text Replacement Strategy Matrix

| Backspace Count | Strategy | Reason |
|-----------------|----------|--------|
| 0 | None | No replacement needed |
| 1 | Backspace | Single char, fast |
| 2-3 | Backspace | Compound vowels |
| 4+ | Backspace | Longer shortcuts |

### Known Compatible Apps

| Category | Apps | Method |
|----------|------|--------|
| **Browsers** | Chrome, Safari, Firefox, Arc | Backspace (body), Selection (address bar) |
| **IDEs** | VS Code, Xcode, Sublime | Backspace |
| **Office** | Pages, Numbers, Word | Backspace |
| **Chat** | Slack, Discord, Telegram, Zalo | Backspace |
| **Terminal** | Terminal.app, iTerm2, Warp | Backspace + IMKit |

### Address Bar Fix

```swift
func getReplacementMethod() -> ReplacementMethod {
    guard let info = getFocusedElementInfo() else {
        return .backspace
    }
    
    // ComboBox = address bar, dropdown
    if info.role == "AXComboBox" {
        return .selection
    }
    
    // Search field with autocomplete
    if info.subrole == "AXSearchField" {
        return .selection
    }
    
    return .backspace
}
```

---

## Accessibility Permission

### macOS Requirement

```swift
// Check permission before starting keyboard hook
let trusted = AXIsProcessTrusted()
if !trusted {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    AXIsProcessTrustedWithOptions(options as CFDictionary)
}
```

### User Flow

1. App requests permission on first run
2. User goes to: **System Settings → Privacy & Security → Accessibility**
3. User enables ZendyKey in the list
4. App can now create CGEventTap

---

## Global Hotkeys

| Hotkey | Default | Action |
|--------|---------|--------|
| Toggle VN/EN | Ctrl+Space | Switch input mode |
| ESC | - | Restore original input |
| Custom | Configurable | User-defined toggle |

---

## IMKit Integration (Optional)

For Terminal and IDE apps that work better with IMKit:

```
┌─────────────────────────────────────────┐
│     ZendyKeyIM.app (Input Method)       │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │     IMKInputController             │ │
│  │  • Marked text support             │ │
│  │  • Candidate window                │ │
│  └─────────────┬──────────────────────┘ │
│                │                         │
│  ┌─────────────▼──────────────────────┐ │
│  │      Shared ZKEngine               │ │
│  │  (Same engine as CGEventTap mode)  │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## Performance Characteristics

### Latency Budget

| Component | Time | Notes |
|-----------|------|-------|
| CGEventTap callback | ~50μs | System kernel time |
| ZKEngine processing | ~100-200μs | Engine logic |
| CGEvent sending | ~100-200μs | Output posting |
| **Total** | **~300-500μs** | <1ms requirement met |

### Memory Profile

| Component | Size | Notes |
|-----------|------|-------|
| ZKEngine instance | ~500KB | Tables + buffers |
| Swift runtime | ~4MB | SwiftUI overhead |
| Word buffer | ~200B | 32 chars max |
| **Total** | **~5MB** | Lightweight |

---

## Initialization Sequence

```
1. AppDelegate.applicationDidFinishLaunching
   ├─ Check first run → show OnboardingView
   └─ Initialize StatusBarManager

2. StatusBarManager.init()
   ├─ Create menu bar icon
   ├─ Load settings from UserDefaults
   ├─ If accessibility trusted: startEngine()
   └─ Otherwise: show permission prompt

3. startEngine()
   ├─ ZKEngine.shared = ZKEngine()
   ├─ ZKKeyboardHandler.shared.start()
   │   └─ Create CGEventTap, enable
   └─ Apply user settings to engine
```

---

## Runtime Flow

```
User types key
   ↓
CGEventTap callback fires
   ↓
Extract keycode + modifier flags
   ↓
Check global hotkey (Ctrl+Space) → Toggle
   ↓
ZKEngine.handleKeyEvent()
   ├─ Process Vietnamese
   └─ Return HookState
   ↓
If transformation:
   ├─ Send backspaces
   ├─ Send replacement chars
   └─ Consume original key
   ↓
Else: Pass through
   ↓
Text appears in app
```

---

*Last updated: 2025-12-23*

[← Back to Documentation](README.md)
