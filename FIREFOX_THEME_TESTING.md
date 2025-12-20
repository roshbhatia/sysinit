# Firefox Theme Testing Guide (Phase 4)

**Status**: Testing procedures & documentation

**Date**: 2025-12-20

---

## Overview

This document provides manual testing procedures and validation checklists for Firefox theme implementations across all 10 color palettes and their variants.

## Testing Environment

### Prerequisites
- macOS system with Firefox installed
- All 10 palettes integrated: Gruvbox, Rose Pine, Catppuccin, Solarized, Nord, Everforest, Kanagawa, Black Metal, Tokyo Night, Monokai
- Configuration built: `task nix:build:lv426`

### Test Scenarios
Each test scenario should be run against at least 3 representative themes:
- **Light theme**: Rose Pine dawn, Tokyo Night day, Monokai light
- **Dark theme**: Gruvbox dark, Tokyo Night night, Monokai dark
- **Medium theme**: Catppuccin macchiato, Everforest dark-medium

---

## Test 1: Semantic Color Variables

### Objective
Verify all semantic CSS variables are accessible and properly themed.

### Procedure

1. Open Firefox Developer Tools (Cmd+Shift+I)
2. Go to Inspector → Computed Styles
3. Search for each variable in root element:

```css
/* Should all be visible and theme-appropriate */
--bg-primary              /* Background main */
--bg-secondary            /* Secondary surface */
--text-primary            /* Main text */
--text-secondary          /* Secondary text */
--accent-primary          /* Main accent */
--accent-dim              /* Dim/border accent */
--color-success           /* Green/success */
--color-warning           /* Yellow/warning */
--color-error             /* Red/error */
```

### Expected Results
✓ All variables accessible
✓ Values are valid hex colors
✓ Values differ appropriately (e.g., primary darker than secondary)
✓ Accent color is distinct from background colors

### Themes to Test
- Light: Rose Pine dawn
- Dark: Gruvbox dark
- Medium: Catppuccin macchiato

---

## Test 2: Menu Interactions

### Objective
Verify menu hover and active states show proper contrast and feedback.

### Procedure

1. Right-click on page → Context menu appears
2. **Hover state**: Move mouse over menu items
   - Background should change subtly (accent-dim)
   - Text should remain readable
   - No flicker or jitter
3. **Click state**: Left-click a menu item
   - Active item should have high contrast (accent-primary background)
   - Text should invert colors if needed
4. **Disabled items**: Check for any disabled items
   - Should appear muted (0.6 opacity)
   - Still readable but clearly disabled

### Checklist
- [ ] Hover background visible
- [ ] Hover transition smooth (150ms)
- [ ] Active state has high contrast
- [ ] Disabled items are visually distinct
- [ ] No contrast violations (text on hover bg ≥ 4.5:1)

### Themes to Test
- Light: Tokyo Night day
- Dark: Monokai dark
- Medium: Nord dark

---

## Test 3: Button & Toolbar Interactions

### Objective
Verify toolbar buttons respond correctly to hover, active, and focus states.

### Procedure

1. **Hover test**: Move mouse over toolbar buttons (back, forward, reload, home)
   - Background color should change (accent-dim visible)
   - Smooth transition (150ms)
   - Text remains readable
2. **Active/click test**: Click a button (or hold menu button)
   - Background changes to accent-primary
   - Text inverts if needed (white on accent)
   - Clear visual feedback that button is active
3. **Focus test**: Press Tab to focus toolbar buttons
   - Focus outline visible (2px solid accent color)
   - Works across keyboard navigation
   - Outline offset 1px for visibility

### Checklist
- [ ] Hover state visible
- [ ] Transition timing correct (150ms)
- [ ] Active state has inverted colors
- [ ] Focus outline visible and positioned correctly
- [ ] Button state changes are consistent

### Themes to Test
- Light: Rose Pine dawn
- Dark: Tokyo Night night
- Medium: Everforest dark-medium

---

## Test 4: URL Bar Focus

### Objective
Verify URL bar shows clear focus indicator for keyboard accessibility.

### Procedure

1. **Normal state**: URL bar at rest
   - Should have subtle border (1px solid accent-dim)
   - Background is secondary color
   - No shadow by default
2. **Focus state**: Click in URL bar or Cmd+L
   - Border becomes more prominent (accent-primary)
   - Subtle shadow appears (0 0 0 2px bg)
   - Text cursor visible
3. **Keyboard test**: Cmd+Tab between windows
   - When Firefox regains focus, URL bar should not lose focus indicator
   - Focus state remains visible

### Checklist
- [ ] Border visible in normal state
- [ ] Border color changes on focus
- [ ] Shadow appears on focus
- [ ] Text is readable (contrast check)
- [ ] Focus indicator persists during window switching

### Themes to Test
- Light: Monokai light
- Dark: Gruvbox dark
- Medium: Catppuccin latte

---

## Test 5: Tab Interactions

### Objective
Verify selected tab and hover states are clearly visible.

### Procedure

1. **Selected tab state**: Open multiple tabs
   - Selected tab should have accent bottom border (2px solid)
   - Tab text is bold and primary color
   - Background is secondary (distinct from unselected)
2. **Hover state**: Mouse over unselected tab
   - Tab label text should brighten
   - Smooth transition (150ms)
   - No change to background (only text)
3. **Close button**: Hover over tab close button
   - Should become more visible
   - Properly themed color
4. **Drag & drop**: Try dragging a tab
   - Visual feedback should remain clear
   - No loss of contrast during drag

### Checklist
- [ ] Selected tab has accent border
- [ ] Unselected tab hover brightens text
- [ ] Transition is smooth
- [ ] Close button visibility improves on hover
- [ ] Tab reordering doesn't break theming

### Themes to Test
- Light: Tokyo Night day
- Dark: Tokyo Night night
- Medium: Kanagawa wave

---

## Test 6: Contrast Validation

### Objective
Verify all UI elements meet WCAG AA contrast requirements (4.5:1 for normal text).

### Procedure

1. Use browser DevTools: Inspector → Accessibility panel
2. Check contrast ratios for:
   - Active menu item text on background
   - Active button text on background
   - Focused tab label
   - URL bar text on secondary background
   - Tab text on background
3. Use online tool: https://webaim.org/resources/contrastchecker/
4. Manual spot checks with color picker:

```bash
# Test color contrast
python3 hack/audit-theme-contrast.py
```

### Checklist
- [ ] Menu item text: ≥ 4.5:1
- [ ] Button text on active: ≥ 4.5:1
- [ ] URL bar text: ≥ 4.5:1
- [ ] Tab text (selected): ≥ 4.5:1
- [ ] All interactive elements pass WCAG AA

### Themes to Test
- All 10 palettes (use contrast script)

---

## Test 7: All Palette Variants

### Objective
Verify every palette variant renders correctly and maintains consistency.

### Procedure

For each palette, test switching themes:

1. Go to Firefox Preferences → Home
2. Change system appearance preference (if theme supports it)
3. Restart Firefox
4. Verify:
   - All UI elements properly themed
   - No missing colors or broken CSS
   - Transitions still work
   - Contrast maintained

### Test Matrix

```
Gruvbox:        dark ✓  light ✓
Rose Pine:      dawn ✓  moon ✓
Catppuccin:     latte ✓  macchiato ✓
Solarized:      dark ✓  light ✓
Nord:           dark ✓
Everforest:     dark-hard ✓  dark-medium ✓  dark-soft ✓  light-hard ✓  light-medium ✓  light-soft ✓
Kanagawa:       lotus ✓  wave ✓  dragon ✓
Black Metal:    gorgoroth ✓
Tokyo Night:    night ✓  storm ✓  day ✓
Monokai:        dark ✓  light ✓
```

### Checklist
- [ ] All 21 variants render without errors
- [ ] Color variables apply correctly
- [ ] No CSS errors in console
- [ ] Transitions work in all variants
- [ ] Contrast maintained in all variants

---

## Test 8: Accessibility Testing

### Objective
Verify Firefox themes support keyboard navigation and screen readers.

### Procedure

1. **Keyboard navigation**:
   - Cmd+Tab: Focus toolbar button
   - Tab: Navigate through toolbar buttons
   - Cmd+L: Focus URL bar
   - Cmd+K: Focus search bar
   - Tab: Navigate tabs
   - Verify focus indicators visible at each step

2. **Focus indicator visibility**:
   - All focused elements should have:
     - 2px outline in accent color
     - 1px offset from element
     - Clear color contrast

3. **Screen reader test** (optional):
   - Enable VoiceOver (Cmd+F5 on macOS)
   - Navigate through UI elements
   - Verify labels and descriptions are read

### Checklist
- [ ] Focus outline visible on all interactive elements
- [ ] Tab order makes sense
- [ ] No keyboard traps
- [ ] Focus outline color has sufficient contrast
- [ ] All buttons/links are keyboard accessible

### Themes to Test
- Light: Rose Pine dawn
- Dark: Monokai dark

---

## Test 9: Edge Cases

### Objective
Test unusual scenarios that might break theming.

### Procedure

1. **New tab page**:
   - Should use theme colors
   - Suggestions/top sites properly styled
   - Search bar themed correctly

2. **Extension pages**:
   - about:extensions
   - about:addons
   - Verify theme applies to extension UI

3. **Firefox preferences**:
   - Settings page should be themed
   - Form inputs should match theme
   - Buttons should have proper states

4. **Private browsing**:
   - All theme colors should still apply
   - No theming breakage in private mode

5. **Fullscreen mode**:
   - Toolbar colors maintain consistency
   - No glitches when entering/exiting fullscreen

### Checklist
- [ ] New tab page properly themed
- [ ] Extension pages use theme colors
- [ ] Settings pages styled correctly
- [ ] Private mode preserves theming
- [ ] Fullscreen mode doesn't break colors

### Themes to Test
- Light & Dark variants

---

## Test 10: Performance

### Objective
Verify theming doesn't cause performance issues.

### Procedure

1. **Open DevTools**: Cmd+Shift+I
2. **Performance tab**: Record page load
   - Hover over UI elements (trigger CSS animations)
   - Monitor for jank or frame drops
   - Check for smooth 60fps transitions

3. **Memory usage**:
   - CSS variables shouldn't increase memory significantly
   - No memory leaks from color calculations

4. **Scrolling performance**:
   - Scroll web pages
   - Should be smooth (60fps)
   - No stuttering related to theming

### Checklist
- [ ] Transitions run at 60fps
- [ ] No jank on UI interactions
- [ ] Memory usage reasonable
- [ ] Scrolling performance not affected
- [ ] No console errors related to CSS

---

## Test 11: Regression Testing

### Objective
Verify new CSS enhancements didn't break existing functionality.

### Procedure

1. **Tab management**:
   - Create 5+ tabs
   - Drag tabs to reorder
   - Close tabs
   - Verify tab styling remains correct

2. **Bookmark bar**:
   - Show/hide bookmark toolbar
   - Add/remove bookmarks
   - Click bookmarks
   - Verify theming applied consistently

3. **Context menus**:
   - Right-click: context menu
   - Right-click: tab context menu
   - Right-click: URL bar context menu
   - All should be themed correctly

4. **Search bar**:
   - Change search engine
   - Type search query
   - Verify search bar styling

5. **Extensions**:
   - Install/uninstall extension
   - Verify extension icons styled correctly
   - Check extension toolbar styling

### Checklist
- [ ] Tab management works normally
- [ ] Bookmark bar functions correctly
- [ ] Context menus fully themed
- [ ] Search bar properly styled
- [ ] Extensions integrate with theme

---

## Testing Checklist Summary

### Quick Reference

```
QUICK TEST (5 min per theme)
- [ ] Hover menu item → accent-dim visible
- [ ] Click menu item → accent-primary, inverted text
- [ ] Hover toolbar button → border visible
- [ ] Click toolbar button → accent background
- [ ] Tab URL bar → focus border & shadow visible
- [ ] Hover unselected tab → text brightens
- [ ] Selected tab → accent bottom border
- [ ] Tab close button → visible on hover

FULL TEST (15 min per theme)
- [ ] All tests 1-11 above
- [ ] Contrast validation on 5+ elements
- [ ] Keyboard navigation check
- [ ] Edge cases (new tab, extensions, prefs)
- [ ] Performance check (no jank)

COMPREHENSIVE TEST (30 min per theme)
- [ ] All FULL test items
- [ ] Accessibility testing with screen reader
- [ ] Regression testing (all features)
- [ ] Document any issues/screenshots
```

---

## Issue Reporting Template

When you find an issue, document it as:

```
### Issue: [Title]

**Palette**: [Gruvbox dark, Tokyo Night day, etc]
**Component**: [Menu, Button, Tab, etc]
**Expected**: [What should happen]
**Actual**: [What actually happens]
**Contrast Ratio**: [If applicable]
**Screenshot**: [Link or attach]
**Steps to Reproduce**:
1. ...
2. ...
3. ...

**Possible Fix**: [If known]
```

---

## Test Results Template

### Theme: [Name]
**Variant**: [dark/light/other]
**Date**: 2025-12-20

| Test | Result | Notes |
|------|--------|-------|
| Semantic Variables | ✓ PASS | All variables accessible |
| Menu Interactions | ✓ PASS | Hover/active states work |
| Button States | ✓ PASS | Focus outline visible |
| URL Bar Focus | ✓ PASS | Border & shadow visible |
| Tab Styling | ✓ PASS | Selected border visible |
| Contrast WCAG AA | ✓ PASS | All elements ≥ 4.5:1 |
| Accessibility | ✓ PASS | Keyboard navigation works |
| Edge Cases | ✓ PASS | No issues found |
| Performance | ✓ PASS | 60fps smooth |
| Regression | ✓ PASS | No breakage |

**Overall**: ✓ APPROVED

---

## Next Steps

1. **Manual Testing**: Run through tests 1-11 for at least 3 representative themes
2. **Document Results**: Fill in test results template for each theme
3. **Bug Fixes**: If issues found, fix and re-test
4. **User Feedback**: Gather feedback on color choices and transitions
5. **Fine-tuning**: Adjust transition timing or colors based on feedback
6. **Documentation**: Update README with theme usage guide

---

## Resources

- **Contrast Checker**: `hack/audit-theme-contrast.py`
- **CSS Validator**: `hack/validate-firefox-css.sh`
- **WCAG Guidelines**: https://www.w3.org/WAI/WCAG21/quickref/
- **Mozilla Docs**: https://developer.mozilla.org/en-US/docs/Tools/Inspector
- **Color Contrast**: https://webaim.org/resources/contrastchecker/

---

## Timeline

- [ ] Week 1: Quick tests on 3 themes (Light, Dark, Medium)
- [ ] Week 2: Full tests on all 10 palettes
- [ ] Week 3: Accessibility & regression testing
- [ ] Week 4: Bug fixes & fine-tuning
- [ ] Week 5: Documentation & user testing

---

## Sign-off

Testing completed by: ___________________
Date: ___________________
Overall status: [ ] APPROVED [ ] NEEDS FIXES [ ] NEEDS REVIEW
