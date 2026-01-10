//
//  ZKEnglishPatternDetector.swift
//  ZendyKey
//
//  Enhanced English pattern detection for auto-restore feature.
//  Includes comprehensive impossible prefix detection and Telex-aware validation.
//

import Foundation

/// Detects English word patterns to improve auto-restore accuracy.
/// Uses multi-tier pattern detection with O(1) Set lookups.
struct ZKEnglishPatternDetector {
    
    // MARK: - Impossible Starting Characters
    
    /// Characters that NEVER start a Vietnamese word: f, j, w, z
    private static let impossibleStartingChars: Set<Character> = ["f", "j", "w", "z"]
    
    // MARK: - Valid Vietnamese Input Sequences (Telex)
    
    /// Valid 2-letter starting patterns for TELEX input
    /// These produce valid Vietnamese characters and should NOT be blocked
    private static let validTelexStartingPatterns: Set<String> = [
        "dd",  // dd → đ
        "cc",  // cc → ch (Quick Telex)
        "gg",  // gg → gi (Quick Telex)
        "kk",  // kk → kh (Quick Telex)
        "nn",  // nn → ng (Quick Telex)
        "qq",  // qq → qu (Quick Telex)
        "pp",  // pp → ph (Quick Telex)
        "tt",  // tt → th (Quick Telex)
    ]
    
    // MARK: - Impossible 2-Letter Prefixes
    
    /// 2-letter clusters IMPOSSIBLE in Vietnamese
    private static let impossible2LetterPrefixes: Set<String> = [
        // L-clusters (Vietnamese NEVER has these)
        "bl", "cl", "dl", "fl", "gl", "hl", "jl", "kl", "ml", "nl",
        "pl", "rl", "sl", "tl", "vl", "wl", "xl", "yl", "zl",
        
        // R-clusters (Vietnamese only has "tr")
        "br", "cr", "dr", "fr", "gr", "hr", "jr", "kr", "lr", "mr", "nr",
        "pr", "rr", "sr", "vr", "wr", "xr", "zr",
        
        // S-clusters
        "sb", "sc", "sd", "sf", "sg", "sh", "sj", "sk", "sl", "sm",
        "sn", "sp", "sq", "sr", "ss", "st", "sv", "sw", "sx", "sz",
        
        // W-clusters (Vietnamese NEVER uses 'w')
        "wa", "wb", "wc", "wd", "we", "wf", "wg", "wh", "wi", "wj",
        "wk", "wl", "wm", "wn", "wo", "wp", "wq", "wr", "ws", "wt",
        "wu", "wv", "ww", "wx", "wy", "wz",
        
        // F-clusters (Vietnamese NEVER uses 'f')
        "fa", "fb", "fc", "fd", "fe", "ff", "fg", "fh", "fi", "fj",
        "fk", "fl", "fm", "fn", "fo", "fp", "fq", "fr", "fs", "ft",
        "fu", "fv", "fw", "fx", "fy", "fz",
        
        // J-clusters (Vietnamese NEVER uses 'j')
        "ja", "jb", "jc", "jd", "je", "jf", "jg", "jh", "ji", "jj",
        "jk", "jl", "jm", "jn", "jo", "jp", "jq", "jr", "js", "jt",
        "ju", "jv", "jw", "jx", "jy", "jz",
        
        // Z-clusters (Vietnamese NEVER uses 'z')
        "za", "zb", "zc", "zd", "ze", "zf", "zg", "zh", "zi", "zj",
        "zk", "zl", "zm", "zn", "zo", "zp", "zq", "zr", "zs", "zt",
        "zu", "zv", "zw", "zx", "zy", "zz",
        
        // Consonant + W (except valid qu)
        "bw", "cw", "dw", "gw", "hw", "kw", "lw", "mw", "nw", "pw",
        "rw", "sw", "tw", "vw", "xw", "yw",
        
        // Silent letter patterns
        "gn", "kn", "pn", "ps", "pt", "pf", "ks", "ts", "tz",
        
        // Double consonants (exclude Telex: dd, cc, gg, kk, nn, pp, tt, qq)
        "bb", "ff", "hh", "jj", "ll", "mm", "rr", "ss", "vv", "ww", "xx", "zz",
        
        // B + consonant
        "bc", "bd", "bf", "bg", "bh", "bj", "bk", "bm", "bn", "bp", "bq", "bs", "bt", "bv", "bx", "by", "bz",
        // C + consonant (except ch)
        "cb", "cd", "cf", "cg", "cj", "ck", "cm", "cn", "cp", "cq", "cs", "ct", "cv", "cx", "cy", "cz",
        // D + consonant
        "db", "dc", "df", "dg", "dh", "dj", "dk", "dm", "dn", "dp", "dq", "ds", "dt", "dv", "dx", "dy", "dz",
        // G + consonant (except gh, gi)
        "gb", "gc", "gd", "gf", "gj", "gk", "gm", "gp", "gq", "gs", "gt", "gv", "gx", "gy", "gz",
        // H + consonant
        "hb", "hc", "hd", "hf", "hg", "hj", "hk", "hl", "hm", "hn", "hp", "hq", "hr", "hs", "ht", "hv", "hx", "hz",
        // K + consonant (except kh)
        "kb", "kc", "kd", "kf", "kg", "kj", "kl", "km", "kp", "kq", "ks", "kt", "kv", "kx", "kz",
        // L + consonant
        "lb", "lc", "ld", "lf", "lg", "lh", "lj", "lk", "lm", "ln", "lp", "lq", "lr", "ls", "lt", "lv", "lx", "lz",
        // M + consonant
        "mb", "mc", "md", "mf", "mg", "mh", "mj", "mk", "ml", "mn", "mp", "mq", "mr", "ms", "mt", "mv", "mx", "mz",
        // N + consonant (except ng, nh)
        "nb", "nc", "nd", "nf", "nj", "nk", "nl", "nm", "np", "nq", "nr", "ns", "nt", "nv", "nx", "nz",
        // P + consonant (except ph)
        "pb", "pc", "pd", "pg", "pj", "pk", "pm", "pq", "pv", "px", "py", "pz",
        // R + consonant
        "rb", "rc", "rd", "rf", "rg", "rh", "rj", "rk", "rl", "rm", "rn", "rp", "rq", "rs", "rt", "rv", "rx", "rz",
        // T + consonant (except th, tr)
        "tb", "tc", "td", "tf", "tg", "tj", "tk", "tl", "tm", "tn", "tp", "tq", "ts", "tv", "tx", "tz",
        // V + consonant
        "vb", "vc", "vd", "vf", "vg", "vh", "vj", "vk", "vl", "vm", "vn", "vp", "vq", "vs", "vt", "vv", "vx", "vz",
        // X + consonant
        "xb", "xc", "xd", "xf", "xg", "xh", "xj", "xk", "xl", "xm", "xn", "xp", "xq", "xs", "xt", "xv", "xx", "xz",
    ]
    
    // MARK: - Impossible 3-Letter Prefixes
    
    private static let impossible3LetterPrefixes: Set<String> = [
        // STR family
        "str", "spr", "spl", "scr", "shr", "squ", "stw", "swr",
        // SCH family
        "sch", "scl", "skr", "skw", "sph", "sth",
        // THR family
        "thr", "thw",
        // CHR/SHR/PHR family
        "chr", "phr",
        // Other 3-letter clusters
        "dge", "dgi", "kni", "pne", "psy", "gho", "ghu", "wri", "wro", "wra",
        "ght", "ghr", "ghl", "ghw", "ntr", "mpr", "xtr",
        // GR/GL extended
        "gra", "gre", "gri", "gro", "gru", "gry",
        "gla", "gle", "gli", "glo", "glu", "gly",
        // BR/BL extended
        "bra", "bre", "bri", "bro", "bru", "bry",
        "bla", "ble", "bli", "blo", "blu", "bly",
        // DR extended
        "dra", "dre", "dri", "dro", "dru", "dry",
        // CR/CL extended
        "cra", "cre", "cri", "cro", "cru", "cry",
        "cla", "cle", "cli", "clo", "clu", "cly",
        // PR/PL extended
        "pra", "pre", "pri", "pro", "pru", "pry",
        "pla", "ple", "pli", "plo", "plu", "ply",
        // FR/FL extended
        "fra", "fre", "fri", "fro", "fru", "fry",
        "fla", "fle", "fli", "flo", "flu", "fly",
        // WR extended
        "wra", "wre", "wri", "wro", "wru",
    ]
    
    // MARK: - Impossible 4-Letter Prefixes
    
    private static let impossible4LetterPrefixes: Set<String> = [
        // SCHR/SCHW family
        "schr", "schw", "schn", "schm", "schl",
        // STRI/STRA family
        "stra", "stre", "stri", "stro", "stru", "stry",
        // SPRI/SPRA family
        "spra", "spre", "spri", "spro", "spru", "spry",
        // SCRA/SCRE family
        "scra", "scre", "scri", "scro", "scru", "scry",
        // SPLA/SPLE family
        "spla", "sple", "spli", "splo", "splu",
        // SQUA/SQUE family
        "squa", "sque", "squi", "squo",
        // THRO/THRA family
        "thra", "thre", "thri", "thro", "thru", "thry",
        // CHRO/CHRA family
        "chra", "chre", "chri", "chro", "chru",
        // PHRA/PHRE family
        "phra", "phre", "phri", "phro",
        // SHRA/SHRE family
        "shra", "shre", "shri", "shro", "shru",
        // Other
        "psyc", "pneu", "ghri",
    ]
    
    // MARK: - Invalid Endings
    
    /// Consonants that NEVER end Vietnamese words
    private static let invalidEndingChars: Set<Character> = ["b", "d", "g", "k", "l", "r", "s", "v", "x", "f", "z", "j", "w"]
    
    /// English-only final clusters
    private static let englishFinalClusters: Set<String> = [
        "ck", "sk", "nk", "lk", "rk",
        "ct", "ft", "pt", "xt", "lt", "st",
        "lp", "mp", "sp",
        "nd", "ld", "rd",
        "nt", "lf", "lm", "lb", "rb", "rm",
        "ght", "tch", "dge"
    ]
    
    // MARK: - Programming Keywords (embedded)
    
    /// Common programming keywords for developers - embedded for O(1) access
    private static let programmingKeywords: Set<String> = [
        // Common English words (look like Vietnamese)
        "text", "next", "test", "best", "rest", "west", "expect", "express",
        "file", "fix", "function", "firebase", "figure", "find", "first",
        "window", "water", "write", "what", "when", "where", "which", "while",
        "user", "use", "using", "update", "upload",
        "their", "there", "these", "those", "think", "thing",
        "pair", "fair", "hair", "chair", "stair",
        "wow", "now", "how", "pow", "cow", "row", "low", "bow",
        "just", "must", "bust", "dust", "rust", "trust",
        "push", "pull", "full", "bull",
        "sort", "port", "fort", "short", "sport",
        
        // Variables & Types
        "const", "let", "var", "int", "float", "bool", "string", "char", "void",
        "null", "nil", "true", "false", "array", "list", "map", "set", "dict",
        "tuple", "enum", "struct", "class", "object", "type", "typeof", "instanceof",
        
        // Control Flow
        "if", "else", "elif", "switch", "case", "break", "continue", "return",
        "yield", "for", "foreach", "while", "do", "loop", "try", "catch", "throw",
        "throws", "finally", "except", "raise",
        
        // Functions & Classes
        "func", "def", "async", "await", "static", "public", "private", "protected",
        "final", "abstract", "interface", "implements", "extends", "override",
        "super", "self", "this", "new", "delete", "import", "export", "from",
        "as", "require", "module", "package",
        
        // Web Development
        "html", "css", "script", "style", "body", "head", "div", "span", "input",
        "button", "form", "submit", "fetch", "axios", "http", "https", "url",
        "uri", "api", "rest", "json", "xml", "dom", "node", "element", "event",
        "click", "hover", "focus", "blur", "scroll", "resize", "load", "error",
        
        // React/Vue/Angular
        "component", "props", "state", "hook", "effect", "ref", "memo", "context",
        "provider", "consumer", "dispatch", "action", "reducer", "store", "selector",
        "computed", "watch", "mount", "unmount", "render",
        
        // Node.js / Backend
        "server", "client", "request", "response", "middleware", "router",
        "controller", "service", "model", "schema", "database", "query",
        "insert", "select", "update", "delete", "where", "join", "group",
        
        // Git / DevOps
        "git", "commit", "push", "pull", "merge", "branch", "checkout", "rebase",
        "stash", "clone", "fetch", "remote", "origin", "master", "main", "develop",
        "feature", "hotfix", "release", "tag", "version",
        
        // Common Dev Terms
        "debug", "log", "print", "console", "output", "stream", "buffer", "cache",
        "memory", "stack", "heap", "queue", "thread", "process", "sync", "promise",
        "callback", "closure", "scope", "global", "local", "param", "argument",
        "option", "config", "setting",
        
        // Testing
        "spec", "describe", "expect", "assert", "mock", "stub", "spy", "before",
        "after", "each", "setup", "teardown", "suite",
        
        // File Operations
        "read", "write", "open", "close", "save", "create", "remove", "move",
        "copy", "rename", "path", "folder", "directory",
        
        // Math & Logic
        "max", "min", "sum", "avg", "count", "abs", "round", "floor", "ceil",
        "sqrt", "pow", "exp", "sin", "cos", "tan", "random", "seed",
        
        // Chrome/Browser
        "chrome", "browser", "tab", "bookmark", "history", "cookie", "storage",
        "session", "extension", "plugin", "addon", "devtools",
        
        // IDE/Editor
        "workspace", "editor", "cursor", "selection", "line", "column", "indent",
        "format", "lint", "syntax", "highlight", "autocomplete", "snippet",
        "refactor", "extract", "inline", "rename", "goto", "definition",
        
        // Tech Abbreviations
        "id", "uid", "uuid", "pid", "tid", "src", "dst", "tmp", "temp", "dev",
        "prod", "env", "cfg", "ini", "exe", "bin", "lib", "pkg", "mod", "dep"
    ]
    
    // MARK: - Main Detection Methods
    
    /// Ultra-fast: Check if word starts with impossible Vietnamese cluster
    static func startsWithImpossibleVietnameseCluster(_ word: String, allowZFWJ: Bool = false) -> Bool {
        let lower = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lower.isEmpty else { return false }
        
        // Check starting character (f, j, w, z)
        if !allowZFWJ, let firstChar = lower.first, impossibleStartingChars.contains(firstChar) {
            return true
        }
        
        guard lower.count >= 2 else { return false }
        let prefix2 = String(lower.prefix(2))
        
        // Skip if valid Telex pattern
        if validTelexStartingPatterns.contains(prefix2) {
            return false
        }
        
        // Check 2-letter prefix
        if impossible2LetterPrefixes.contains(prefix2) {
            return true
        }
        
        // Check 3-letter prefix
        if lower.count >= 3 {
            let prefix3 = String(lower.prefix(3))
            if impossible3LetterPrefixes.contains(prefix3) {
                return true
            }
        }
        
        // Check 4-letter prefix
        if lower.count >= 4 {
            let prefix4 = String(lower.prefix(4))
            if impossible4LetterPrefixes.contains(prefix4) {
                return true
            }
        }
        
        return false
    }
    
    /// Check if word ends with invalid Vietnamese consonant
    static func hasInvalidEnding(_ word: String) -> Bool {
        let lower = word.lowercased()
        guard lower.count >= 2, let lastChar = lower.last else { return false }
        
        // Single character ending
        if invalidEndingChars.contains(lastChar) {
            return true
        }
        
        // Cluster endings
        if lower.count >= 3 {
            let last3 = String(lower.suffix(3))
            if englishFinalClusters.contains(last3) { return true }
        }
        if lower.count >= 2 {
            let last2 = String(lower.suffix(2))
            if englishFinalClusters.contains(last2) { return true }
        }
        
        return false
    }
    
    /// Check if word has 'x' in middle (English pattern)
    static func hasXInMiddle(_ word: String) -> Bool {
        let lower = word.lowercased()
        guard lower.count >= 3 else { return false }
        let middle = lower.dropFirst().dropLast()
        return middle.contains("x")
    }
    
    /// Check if 'q' not followed by 'u' (English pattern)
    static func hasQWithoutU(_ word: String) -> Bool {
        let lower = word.lowercased()
        guard let qIndex = lower.firstIndex(of: "q") else { return false }
        let afterQ = lower.index(after: qIndex)
        return afterQ >= lower.endIndex || lower[afterQ] != "u"
    }
    
    /// Check if word contains 'io' sequence (English -tion, action)
    static func hasIOSequence(_ word: String) -> Bool {
        let lower = word.lowercased()
        return lower.count >= 3 && lower.contains("io")
    }
    
    /// Check if word is a programming keyword
    static func isProgrammingKeyword(_ word: String) -> Bool {
        return programmingKeywords.contains(word.lowercased())
    }
    
    // MARK: - Combined Detection
    
    /// Check if word matches English patterns (comprehensive)
    static func isEnglish(_ word: String) -> Bool {
        // Quick keyword check (O(1))
        if isProgrammingKeyword(word) { return true }
        
        // Impossible prefix (most reliable)
        if startsWithImpossibleVietnameseCluster(word) { return true }
        
        // Invalid ending
        if hasInvalidEnding(word) { return true }
        
        // 'x' in middle
        if hasXInMiddle(word) { return true }
        
        // 'q' without 'u'
        if hasQWithoutU(word) { return true }
        
        // 'io' sequence
        if hasIOSequence(word) { return true }
        
        return false
    }
}
