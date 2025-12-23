# Common Issues & Troubleshooting

> Solutions for common problems when using Vietnamese typing on macOS.

---

## Installation Issues

### App Can't Be Opened (Unverified Developer)

```bash
# Run in Terminal after installing
xattr -cr /Applications/ZendyKey.app
```

Then: **System Settings → Privacy & Security → Open Anyway**

### Accessibility Permission Not Working

1. Go to: **System Settings → Privacy & Security → Accessibility**
2. Remove ZendyKey from the list (click `-`)
3. Re-add ZendyKey (click `+`)
4. Restart ZendyKey

### Secure Input Blocking

**Symptom:** Vietnamese typing stops working after entering password

**Cause:** Some apps enable "Secure Input" mode and don't release it

**Solution:**
- Close the password prompt/app
- Or: Log out and log back in to reset Secure Input

---

## Typing Issues

### Not Typing Vietnamese

| Check | Solution |
|-------|----------|
| Is ZendyKey enabled? | Click menu bar icon → Enable |
| Correct input method? | Check Telex/VNI/VIQR setting |
| Per-app mode? | May be disabled for this app |
| Accessibility? | Re-grant permission |

### Double Characters (đđược, hhọc)

**Apps affected:** Discord, Slack, Electron apps

**Solution:**
- Try IMKit mode in Settings
- Or: Type slower in affected apps

### Chrome/Arc Address Bar Issues

**Symptom:** Text sticks together when typing in URL bar

**Solution:** Already auto-detected. If issue persists:
- Settings → Enable "Fix browser autocomplete"

### Tone Mark on Wrong Vowel

**Check orthography setting:**
- Modern: hoà, khoẻ, thuỷ (tone on second vowel)
- Traditional: hòa, khoẻ, thủy (tone on first vowel)

**Settings → Use Modern Orthography**

---

## Application-Specific Issues

### Google Docs

**Symptom:** Duplicate characters or lost tones

**Solutions:**
1. Type slower
2. Disable browser extensions
3. Try different browser

### Microsoft Excel

**Symptom:** ư, ơ characters lost when editing cell

**Solution:** Type complete word before pressing Enter

### Terminal/Vim

**Symptom:** Cursor jumps, Esc key issues

**Solutions:**
1. Use IMKit mode for Terminal
2. Switch to English when typing commands
3. Add Terminal to per-app English mode

### JetBrains IDEs

**Symptom:** Code completion conflicts

**Solution:** Already auto-detected for selection mode

---

## Performance Issues

### High CPU Usage

1. Restart ZendyKey
2. Check Console.app for errors
3. Re-grant Accessibility permission

### Slow Response

1. Close and restart ZendyKey
2. Check if multiple input methods running
3. Reinstall if needed

---

## Quick Reference

### Keyboard Shortcuts

| Action | Default Hotkey |
|--------|---------------|
| Toggle VN/EN | Ctrl+Space |
| Restore original | ESC |
| Open settings | Click menu bar icon |

### Settings Location

```
~/Library/Preferences/com.zendy199x.ZendyKey.plist
```

### Logs Location

```
~/Library/Logs/ZendyKey/
```

---

## Getting Help

If issues persist:

1. Check [GitHub Issues](https://github.com/zendy199x/ZendyKey/issues)
2. Create new issue with:
   - macOS version
   - ZendyKey version
   - Steps to reproduce
   - Affected app name

---

*Last updated: 2025-12-23*

[← Back to Documentation](README.md)
