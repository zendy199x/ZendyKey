# ZendyKey Engine Algorithm

> Comprehensive algorithm documentation for the Vietnamese typing engine.

**Related Documents**:
- [Architecture](./architecture.md) - System architecture
- [Development](./development.md) - Build and test guide
- [Common Issues](./common-issues.md) - Troubleshooting

---

## 1. Design Principles

```
PRINCIPLES:
│
├── 1. VALIDATION FIRST (★ Most Important)
│   └── Before transform → validate if buffer is valid Vietnamese
│       ├── "nghieng" valid? → YES → allow transform
│       ├── "claus" valid? → NO → skip transform
│       └── If INVALID → add key to buffer normally
│
├── 2. PATTERN-BASED REPLACEMENT
│   └── If VALID → scan ENTIRE buffer → apply pattern
│       ├── Not case-by-case (prev + current)
│       └── Scan whole buffer to find patterns
│
├── 3. LONGEST-MATCH-FIRST
│   └── For tone placement and final matching
│       ├── "nghieng" → find "ieng" → place tone correctly
│       └── "ch", "ng", "nh" match before "c", "n"
│
└── 4. DOUBLE-KEY REVERT
    └── Press same key twice → revert transformation
        ├── "aa" → "â", "aa" again → "aa" (revert)
        └── "ss" → "á", "ss" again → "as" (revert)
```

---

## 2. Processing Pipeline

### 2.1 Main Event Flow

```
handleKeyEvent(keyCode, character, isUppercase, hasOtherModifier)
│
├─► [hasOtherModifier?] ──► reset buffer ──► return DoNothing
│
├─► [isWordBreak?] ──► try auto-restore ──► clear buffer ──► return
│
├─► [KEY_DELETE?] ──► handle backspace ──► return
│
├─► [ESC key?] ──► restore to raw input ──► return
│
└─► handleNormalKey(keyCode, character, isCaps)
    │
    ├── STAGE 1: Consonant Check
    │   └── Quick Telex (cc→ch, gg→gi, nn→ng, kk→kh, pp→ph)
    │
    ├── STAGE 2: Stroke Transform (d → đ)
    │   └── Check for 'd' key → apply stroke
    │
    ├── STAGE 3: Tone Transform (circumflex/horn/breve)
    │   └── aa→â, oo→ô, ee→ê, ow→ơ, uw→ư, aw→ă
    │
    ├── STAGE 4: Mark Transform (sắc/huyền/hỏi/ngã/nặng)
    │   └── s→sắc, f→huyền, r→hỏi, x→ngã, j→nặng
    │
    ├── STAGE 5: Remove Mark (z/0)
    │   └── Clear current mark or tone
    │
    ├── STAGE 6: W-Vowel (Telex only)
    │   └── "w" → "ư" with validation
    │
    └── STAGE 7: Normal Letter
        └── Push to buffer
```

### 2.2 HookState Result

```swift
struct HookState {
    var code: UInt8            // 0: DoNothing, 1: Process, 2: WordBreak
                               // 3: Restore, 4: ReplaceMacro
    var backspaceCount: Int    // Characters to delete
    var newCharacters: [ZKChar] // Characters to insert
    var macroKey: [UInt16]     // For macro expansion
}
```

---

## 3. Input Methods

### 3.1 Telex Modifiers

| Type | Keys | Example |
|------|------|---------|
| **Tone (dấu phụ)** | a→â, e→ê, o→ô | aa→â, ee→ê, oo→ô |
| **Horn** | w | ow→ơ, uw→ư |
| **Breve** | w | aw→ă |
| **Stroke** | d | dd→đ |
| **Mark (dấu thanh)** | s,f,r,x,j | as→á, af→à, ar→ả, ax→ã, aj→ạ |
| **Remove** | z | Remove current mark |

### 3.2 VNI Modifiers

| Type | Keys | Example |
|------|------|---------|
| **Circumflex** | 6 | a6→â, e6→ê, o6→ô |
| **Horn** | 7 | o7→ơ, u7→ư |
| **Breve** | 8 | a8→ă |
| **Stroke** | 9 | d9→đ |
| **Marks** | 1,2,3,4,5 | a1→á, a2→à, a3→ả, a4→ã, a5→ạ |
| **Remove** | 0 | Remove current mark |

### 3.3 Quick Telex (Unique to ZendyKey)

| Input | Output | Description |
|-------|--------|-------------|
| cc | ch | Consonant cluster |
| gg | gi | Quick "gi" |
| nn | ng | Quick "ng" |
| kk | kh | Quick "kh" |
| pp | ph | Quick "ph" |

---

## 4. Syllable Structure

```
Vietnamese Syllable = (C₁)(G)V(C₂)

C₁ = Initial consonant (optional)
├── Single: b, c, d, g, h, k, l, m, n, p, q, r, s, t, v, x
├── Double: ch, gh, gi, kh, ng, nh, ph, qu, th, tr
└── Triple: ngh

G = Glide (optional)
└── o (oa, oe), u (uy, ue)

V = Vowel nucleus (REQUIRED)
└── a, ă, â, e, ê, i, o, ô, ơ, u, ư, y

C₂ = Final consonant (optional)
├── Consonants: c, m, n, p, t
├── Clusters: ch, ng, nh
└── Semi-vowels: i, y, o, u
```

---

## 5. Tone Placement Rules

### 5.1 Algorithm

```
findTonePosition(vowels, hasFinal, isModern) → position
│
├── Single vowel: return vowel position
│
├── Double vowel:
│   ├── Has final? → return vowel[1] (second)
│   ├── Has diacritic (ư,ơ,ô,ê,â,ă)? → return that one
│   ├── Pattern oa, oe, uy? → return vowel[1]
│   ├── Pattern ai, ao, au? → return vowel[0]
│   └── Default → return vowel[0]
│
└── Triple vowel: return vowel[1] (middle)
```

### 5.2 Modern vs Traditional

| Word | Modern (default) | Traditional |
|------|------------------|-------------|
| hoà | ho**à** | h**ò**a |
| khoẻ | kho**ẻ** | kh**ỏ**e |
| thuỷ | thu**ỷ** | th**ủ**y |

---

## 6. Advanced Features

### 6.1 Auto-restore English

Automatically restore English words when Space is pressed:

```
PATTERNS DETECTED:
├── Modifier + consonant: text, next, test, expect
├── EI + modifier: their, weird  
├── W at start: window, water, write
├── F at start: file, fix, function
├── Invalid vowel patterns: search, teacher
└── Consonant clusters: metric, spectrum
```

**Example flow:**
```
User types: t e x t [space]
Buffer:     t ê t
Pattern:    "x" followed by consonant "t" → invalid Vietnamese
Action:     Auto-restore to "text"
```

### 6.2 ESC Restore

Restore original keystrokes on ESC key:

```
User types: u s e r
Buffer:     ú ẻ      (after transforms)
User hits:  ESC
Action:     Restore to "user" (original input)
```

### 6.3 State Tracking

| Flag | Purpose |
|------|---------|
| `rawInput` | Stores (keyCode, caps, shift) for ESC restore |
| `hadAnyTransform` | Tracks if VN transform was applied |
| `pendingBrevePos` | Deferred breve position on 'a' |
| `pendingHornPos` | Deferred horn position on 'u' |
| `hadMarkRevert` | Tracks mark revert for auto-restore |

---

## 7. UO Compound Handling

Special handling for "ươ" compound vowel:

```
When 'w' (Telex) or '7' (VNI) is pressed:
│
├── Find "uo" or "ou" adjacent in buffer
│   ├── Found → Apply HORN to BOTH
│   │   ├── u → ư
│   │   └── o → ơ
│   │
│   └── Not found → Apply to single vowel
│
EXAMPLES:
├── "truong" + 'w' → "trương"
├── "nguoi" + 'w' → "người"  
└── "mua" + 'w' → "mưa" (only u since no "uo")
```

---

## 8. Double-Key Revert

```
MECHANISM:
├── Track lastTransform = { key, pattern, result }
│
├── When modifier pressed again:
│   ├── Same key? → REVERT
│   │   ├── Clear previous transform
│   │   ├── Add key to output
│   │   └── Clear lastTransform
│   │
│   └── Different key? → Apply new transform
│
EXAMPLES:
├── "a" + 'a' → "â" (save: Tone)
├── "â" + 'a' → "aa" (revert)
│
├── "a" + 's' → "á" (save: Mark)
├── "á" + 's' → "as" (revert)
│
├── "d" + 'd' → "đ" (save: Stroke)
└── "đ" + 'd' → "dd" (revert)
```

---

## 9. Example: Complete Flow for "được"

```
User types: d → u → o → c → w → j

1. 'd':
   ├── Stage 7: push 'd' to buffer
   └── buffer = ['d']

2. 'u':
   ├── Stage 7: push 'u' to buffer
   └── buffer = ['d', 'u']

3. 'o':
   ├── Stage 7: push 'o' to buffer
   └── buffer = ['d', 'u', 'o']

4. 'c':
   ├── Stage 7: push 'c' to buffer
   └── buffer = ['d', 'u', 'o', 'c']

5. 'w' (horn modifier):
   ├── Stage 3: Tone transform
   │   ├── Validate: "duoc" → VALID ✓
   │   ├── Find UO compound at positions 1-2
   │   ├── Apply HORN to both: u→ư, o→ơ
   │   └── Return: backspace=3, "ươc"
   └── Output: "dươc"

6. 'j' (nặng modifier):
   ├── Stage 4: Mark transform
   │   ├── Collect vowels: [ư, ơ]
   │   ├── Find position: has_final=true → pos=1 (ơ)
   │   ├── Apply mark: ơ + nặng → ợ
   │   └── Return: backspace=2, "ợc"
   └── Output: "được" ✓
```

---

## 10. Performance

| Component | Latency | Notes |
|-----------|---------|-------|
| Key capture | ~50μs | CGEventTap overhead |
| Engine processing | ~100-200μs | Swift native |
| Output sending | ~100μs | CGEvent posting |
| **Total** | **<500μs** | <1ms requirement met |

---

*Last updated: 2025-12-23*

[← Back to Documentation](README.md)
