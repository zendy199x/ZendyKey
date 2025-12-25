# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in ZendyKey, please report it responsibly.

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email us at: **security@zendy199x.dev** (or via GitHub private message)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if you have one)

### What to Expect

- We will acknowledge your report within **48 hours**
- We will investigate and respond with our findings within **7 days**
- If the vulnerability is confirmed, we will:
  - Work on a fix
  - Credit you in the release notes (if you wish)
  - Notify you when the fix is released

### Scope

Security issues we care about:

- **Data privacy**: Any way ZendyKey could leak user keystrokes or personal data
- **Code execution**: Vulnerabilities that could allow arbitrary code execution
- **Privilege escalation**: Ways to bypass macOS permissions
- **Denial of service**: Crashes or resource exhaustion

### Out of Scope

- Issues in third-party dependencies (please report those upstream)
- Social engineering attacks
- Physical access attacks

## Security Design

ZendyKey is designed with privacy in mind:

- 🔒 **100% Offline**: No network connections, no data transmission
- 🚫 **No Telemetry**: No analytics, no crash reporting
- 📂 **Local Storage Only**: All data stored in local UserDefaults
- 🔓 **Open Source**: Full transparency - audit the code yourself

## Auditing

The entire codebase is open source. We encourage security researchers to:

1. Clone the repository
2. Review the code, especially:
   - `ZKEventTapManager.swift` - Keyboard event handling
   - `ZKSharedSettings.swift` - Settings storage
   - `ZKEngine.swift` - Text processing

Thank you for helping keep ZendyKey secure! 🙏
