# Firefox Theme Quick Test Guide

**Purpose**: 5-minute manual verification checklist for each theme  
**Representative Themes**: Gruvbox dark, Tokyo Night day, Catppuccin macchiato

---

## Before You Start

1. Open Firefox
2. Have DevTools ready: `Cmd+Shift+I`
3. Open a new tab for testing
4. Ensure configuration is built: `task nix:build:lv426`

---

## 5-Minute Test Per Theme

### 1. Hover Menu Item (30 seconds)
```
1. Right-click on page
2. Hover over menu item
3. Check: Background changes color (accent-dim)
4. Check: Transition is smooth (no flickering)
```

### 2. Click Menu Item (30 seconds)
```
1. Right-click again
2. Click a menu item
3. Check: Active state has high contrast
4. Check: Text is clearly visible
```

### 3. Hover Toolbar Button (30 seconds)
```
1. Hover over back/forward/reload button
2. Check: Background changes (accent-dim visible)
3. Check: Smooth 150ms transition
```

### 4. Click Toolbar Button (30 seconds)
```
1. Hold down menu button (hamburger)
2. Check: Active state has inverted colors
3. Check: Clear visual feedback
```

### 5. URL Bar Focus (30 seconds)
```
1. Press Cmd+L
2. Check: Border visible (accent-primary)
3. Check: Subtle shadow appears
4. Check: Text is readable
```

### 6. Tab Selection (30 seconds)
```
1. Open 2+ tabs
2. Check: Selected tab has bottom border (accent color)
3. Hover unselected tab → text brightens
4. Check: Smooth transition
```

### 7. Keyboard Navigation (30 seconds)
```
1. Press Tab to navigate
2. Check: Focus outline visible on buttons
3. Check: Focus outline is clear and readable
```

---

## Pass/Fail Checklist

```
□ Menu hover state visible
□ Menu active state high contrast
□ Button hover state works
□ Button active state inverted
□ URL bar focus has border + shadow
□ Tab selection indicator visible
□ Tab hover brightens text
□ Keyboard focus outline visible
□ All transitions smooth (150ms)
□ No console errors (check DevTools)
```

---

## If Everything Passes

Mark theme as ✅ PASS in `FIREFOX_THEME_TESTING_RESULTS.md`:

```markdown
**Test 1: [THEME]** | ✅ PASS | All interactions work smoothly
```

---

## If Something Fails

Document issue using template:

```markdown
### Issue: [Brief Title]

**Theme**: [Gruvbox dark, etc]
**Component**: [Menu, Button, Tab, etc]
**Expected**: [What should happen]
**Actual**: [What actually happens]
**Steps**:
1. ...
2. ...
3. ...

**Screenshot**: [If possible]
**Possible Fix**: [If known]
```

---

## Quick Reference: Expected Behavior

| Element | State | Expected | Color |
|---------|-------|----------|-------|
| Menu item | Hover | Background changes | accent-dim |
| Menu item | Active | Background inverts | accent-primary |
| Button | Hover | Background visible | accent-dim |
| Button | Active | Background inverts | accent-primary |
| URL bar | Focus | Border + shadow | accent-primary |
| Tab | Selected | Bottom border | accent-primary |
| Tab | Hover | Text brightens | text-primary |
| All | Focus | 2px outline | accent-primary |

---

## Test Themes in Order

1. **Gruvbox dark** (dark theme) - Expected: warm brown/tan colors
2. **Tokyo Night day** (light theme) - Expected: light blue/gray colors
3. **Catppuccin macchiato** (medium theme) - Expected: balanced pastel colors

---

## Notes

- All 3 themes should behave identically
- Only colors should differ between themes
- All transitions should feel smooth (150ms)
- No console errors expected
- Focus indicators essential for accessibility

