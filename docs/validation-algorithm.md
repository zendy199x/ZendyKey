# Validation Algorithm

> Algorithm for validating Vietnamese syllables before transformation.

**Related**: [Engine Algorithm](./engine-algorithm.md) | [Architecture](./architecture.md)

---

## 1. Purpose

```
Validation occurs BEFORE transformation:

"duoc" + j → VALID   → transform → "được" ✓
"claus" + s → INVALID → keep raw → "clauss" ✓
"http" + s → INVALID → keep raw → "https" ✓
```

**Protects**: code (`function`, `const`), proper names (`John`, `Claude`), loanwords (`pizza`), URLs/email.

---

## 2. Syllable Structure

```
Syllable = (C₁)(G)V(C₂)

C₁ = Initial consonant (optional)
G  = Glide (o, u)        (optional)
V  = Vowel nucleus       (REQUIRED)
C₂ = Final consonant     (optional)
```

| Input | C₁ | G | V | C₂ |
|-------|------|-----|------|------|
| `a` | - | - | a | - |
| `ban` | b | - | a | n |
| `hoa` | h | o | a | - |
| `qua` | qu | - | a | - |
| `giau` | gi | - | au | - |
| `nghieng` | ngh | - | ie | ng |

---

## 3. Data Constants

### 3.1 Valid Initial Consonants (C₁)

```swift
// 16 single consonants
VALID_INITIALS_1 = [b, c, d, g, h, k, l, m, n, p, q, r, s, t, v, x]

// 10 double consonants
VALID_INITIALS_2 = [ch, gh, gi, kh, ng, nh, ph, qu, th, tr]

// 1 triple consonant
VALID_INITIALS_3 = [ngh]
```

### 3.2 Valid Final Consonants (C₂)

```swift
// Single finals (including semi-vowels)
VALID_FINALS_1 = [c, m, n, p, t, i, y, o, u]

// Double finals
VALID_FINALS_2 = [ch, ng, nh]
```

### 3.3 Spelling Rules

| Consonant | Invalid before | Use instead |
|-----------|----------------|-------------|
| `c` | e, i, y | → `k` |
| `k` | a, o, u | → `c` |
| `g` | e | → `gh` |
| `ng` | e, i | → `ngh` |
| `gh` | a, o, u | → `g` |
| `ngh` | a, o, u | → `ng` |

---

## 4. Validation Rules

Engine runs 5 rules sequentially. First failure returns error immediately.

### Rule 1: Must Have Vowel

```swift
if syllable.vowel.isEmpty {
    return .invalidNoVowel
}
```

### Rule 2: Valid Initial Consonant

```swift
switch initial.count {
    case 1: check VALID_INITIALS_1
    case 2: check VALID_INITIALS_2
    case 3: only allow "ngh"
    default: return .invalidInitial
}
```

### Rule 3: All Characters Parsed

```swift
let parsed = initial.count + glide.count + vowel.count + final.count
if parsed != buffer.count {
    return .invalidFinal
}
```

### Rule 4: Spelling Rules

```swift
for (consonant, invalidVowels) in SPELLING_RULES {
    if initial == consonant && firstVowel in invalidVowels {
        return .invalidSpelling
    }
}
```

### Rule 5: Valid Final Consonant

```swift
switch final.count {
    case 1: check VALID_FINALS_1
    case 2: check VALID_FINALS_2
    default: return .invalidFinal
}
```

---

## 5. Foreign Word Detection

Additional check for English/foreign patterns:

```swift
func isForeignWordPattern(buffer, modifierKey) -> Bool
```

### Patterns Detected:

| Pattern | Examples |
|---------|----------|
| Invalid vowel pairs | ea, ou, yo |
| Consonant clusters | T+R, P+R, C+R (metric) |
| English prefix "de" + s | describe, design |
| W at word start | window, water |
| F at word start | file, fix |

---

## 6. Validation Examples

### ✅ Valid Vietnamese

```
ba, ca, an, em, gi, gia, giau, ke, ki, ky
nghe, nghi, nghieng, truong, nguoi, duoc
```

### ❌ Invalid - No Vowel

```
bcd, bcdfg, http
```

### ❌ Invalid - Bad Initial

```
clau, john, bla, string, chrome
```

### ❌ Invalid - Spelling Rule

```
ci, ce, cy     → should use ki, ke, ky
ka, ko, ku     → should use ca, co, cu
ngi, nge       → should use nghi, nghe
ge             → should use ghe
```

### ❌ Invalid - Foreign Words

```
exp, expect, test, claude, claus
search, teacher, beach, real
you, your, house, about
```

---

## 7. Integration with Engine

```
handleKeyEvent(key)
│
├─ [isModifier(key)?]
│  │
│  ├─ ★ VALIDATION: Before transform
│  │   └─ isValid(buffer)?
│  │       ├─ NO  → return DoNothing
│  │       └─ YES → continue transform
│  │
│  └─ Apply transformation
│
└─ [isLetter(key)?] → push to buffer
```

---

*Last updated: 2025-12-23*

[← Back to Documentation](README.md)
