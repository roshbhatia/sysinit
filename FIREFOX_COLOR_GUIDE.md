# Firefox Theme Color Usage Guide

**Date**: 2025-12-20

**Purpose**: Document how to use semantic colors and variables in Firefox CSS customizations.

---

## Color Hierarchy

The Firefox theme system uses a three-level color hierarchy:

### Level 1: Semantic Roles
```
Primary        → Most important, main focus
Secondary      → Supporting elements
Muted          → De-emphasized content
Subtle         → Barely visible, decorative
```

### Level 2: Color Families
```
Background     → UI surfaces (primary, secondary, tertiary, overlay)
Foreground     → Text content (primary, secondary, muted, subtle)
Accent         → Interactive elements (primary, secondary, tertiary, dim)
Semantic       → Status indicators (success, warning, error, info)
```

### Level 3: Theme Colors
```
Base16         → Standard colors (red, orange, yellow, green, cyan, blue, purple)
Syntax         → Code highlighting (keyword, string, number, comment, etc)
Extended       → Theme-specific colors from palette
```

---

## CSS Variable Reference

### Background Colors

```css
--bg-primary              /* Main background color */
--bg-secondary            /* Secondary surface (menus, panels) */
--bg-tertiary             /* Tertiary surface (deeply nested) */
--bg-overlay              /* Overlay/modal background */
```

**Usage Example**:
```css
#navigator-toolbox {
    background-color: var(--bg-primary);
}

#urlbar-background {
    background-color: var(--bg-secondary);
}

.panel {
    background-color: var(--bg-tertiary);
}
```

**Mapping**:
- bg-primary maps to palette `base`
- bg-secondary maps to palette `surface`
- bg-tertiary maps to palette `surface_alt`
- bg-overlay maps to palette `overlay`

---

### Foreground Colors (Text)

```css
--text-primary            /* Main text color */
--text-secondary          /* Secondary text (labels, captions) */
--text-muted              /* Muted text (disabled, hints) */
--text-subtle             /* Barely visible decorative text */
```

**Usage Example**:
```css
/* Body text */
body {
    color: var(--text-primary);
}

/* Labels and secondary text */
label, .caption {
    color: var(--text-secondary);
}

/* Disabled text */
[disabled] {
    color: var(--text-muted);
}

/* Watermarks, placeholders */
::placeholder {
    color: var(--text-subtle);
}
```

**Mapping**:
- text-primary maps to palette `text`
- text-secondary maps to palette `subtext1`
- text-muted maps to palette `subtext0`
- text-subtle maps to palette `subtle` or `overlay`

---

### Accent Colors

```css
--accent-primary          /* Main interactive color */
--accent-secondary        /* Secondary interactive color */
--accent-tertiary         /* Tertiary interactive color */
--accent-dim              /* Dim/border accent */
```

**Usage Example**:
```css
/* Links and primary buttons */
a, button:not([disabled]) {
    color: var(--accent-primary);
}

/* Secondary actions */
button.secondary {
    color: var(--accent-secondary);
}

/* Borders and dividers */
.divider {
    border-color: var(--accent-dim);
}
```

**Mapping**:
- accent-primary maps to palette `accent`
- accent-secondary maps to palette `accent_secondary` or `accent`
- accent-tertiary maps to palette `accent_tertiary` or `accent`
- accent-dim maps to palette `accent_dim`

---

### Semantic Status Colors

```css
--color-success           /* Success/positive state (green) */
--color-warning           /* Warning/caution state (yellow) */
--color-error             /* Error/negative state (red) */
--color-info              /* Info/informational state (blue) */
```

**Usage Example**:
```css
/* Success indicators */
.success, .badge-success {
    color: var(--color-success);
}

/* Warning indicators */
.warning, .alert-warning {
    color: var(--color-warning);
}

/* Error indicators */
.error, .alert-error {
    color: var(--color-error);
}

/* Info indicators */
.info, .badge-info {
    color: var(--color-info);
}
```

**Mapping**:
- color-success maps to semantic.success
- color-warning maps to semantic.warning
- color-error maps to semantic.error
- color-info maps to semantic.info

---

### Base16 Colors

```css
--color-red               /* Error/danger, primary red */
--color-orange            /* Warning accent, secondary warm */
--color-yellow            /* Warning, tertiary yellow */
--color-green             /* Success, primary green */
--color-cyan              /* Info accent, secondary cool */
--color-blue              /* Primary accent alternative */
--color-purple            /* Tertiary accent, purple */
```

**Usage Example**:
```css
/* Terminal colors, syntax highlighting */
.token-red { color: var(--color-red); }
.token-green { color: var(--color-green); }
.token-blue { color: var(--color-blue); }
```

**Mapping**:
- Derived from extended palette colors
- Falls back to semantic equivalents if not defined

---

### Syntax Highlighting Colors

```css
--syntax-keyword          /* Keywords (if, for, while) */
--syntax-string           /* String literals */
--syntax-number           /* Numeric literals */
--syntax-comment          /* Comments */
--syntax-function         /* Function names */
--syntax-variable         /* Variable names */
--syntax-type             /* Type names */
--syntax-operator         /* Operators (+ - * /) */
--syntax-constant         /* Constants/literals */
--syntax-builtin          /* Built-in functions */
```

**Usage Example**:
```css
.token.keyword { color: var(--syntax-keyword); }
.token.string { color: var(--syntax-string); }
.token.number { color: var(--syntax-number); }
.token.comment { color: var(--syntax-comment); }
```

---

### Interactive State Colors

```css
--interactive-hover-bg    /* Background on hover */
--interactive-active-bg   /* Background when active/pressed */
--interactive-active-fg   /* Text when active/pressed */
--interactive-focus-outline /* Focus indicator color */
```

**Usage Example**:
```css
/* Hover state */
button:hover {
    background-color: var(--interactive-hover-bg);
}

/* Active state */
button[active], button:active {
    background-color: var(--interactive-active-bg);
    color: var(--interactive-active-fg);
}

/* Focus state */
button:focus-visible {
    outline: 2px solid var(--interactive-focus-outline);
}
```

---

### Effects & Transparency

```css
--opacity                 /* Main transparency value (0.0-1.0) */
--blur-amount             /* Blur effect amount (in pixels) */
```

**Usage Example**:
```css
.panel {
    background-color: rgba(var(--bg-primary), var(--opacity));
    backdrop-filter: blur(var(--blur-amount));
}
```

---

## Color Contrast Guidelines

### WCAG Standards

| Standard | Ratio | Usage |
|----------|-------|-------|
| **WCAG AA** | 4.5:1 | Minimum for normal text |
| **WCAG AAA** | 7:1 | Enhanced, better readability |
| **Large text** | 3:1 | WCAG AA for large text (18px+) |

### Palette-Specific Contrast Ratios

```
Gruvbox dark:     10.75:1   (Excellent)
Gruvbox light:    10.22:1   (Excellent)

Rose Pine dawn:    6.66:1   (Good)
Rose Pine moon:   11.86:1   (Excellent)

Catppuccin latte:  7.06:1   (Good - AAA)
Catppuccin macchiato: 9.92:1 (Excellent)

Solarized dark:    4.75:1   (Good - AA only)
Solarized light:  12.05:1   (Excellent)

Nord dark:        10.84:1   (Excellent)

Everforest:      5.4-8.15:1 (Good to Excellent)

Kanagawa:        6.19-11.26:1 (Good to Excellent)

Black Metal:     11.67:1   (Excellent)

Tokyo Night:    9.02-10.59:1 (Excellent)

Monokai:       13.94-14.24:1 (Exceptional)
```

### When to Use Each Level

**Primary Text** (body content):
- Use --text-primary
- Requirement: ≥ 4.5:1 contrast (WCAG AA)
- All palettes pass

**Secondary Text** (labels, captions):
- Use --text-secondary
- Requirement: ≥ 4.5:1 contrast (recommended)
- Less critical but preferred

**Muted Text** (disabled, hints):
- Use --text-muted
- Requirement: ≥ 3:1 contrast
- Okay to be less prominent

**Subtle Text** (decorative, watermarks):
- Use --text-subtle
- Requirement: No specific WCAG requirement
- Barely visible intentional

---

## Color Application Patterns

### Pattern 1: Text on Background

```css
/* DO: Use appropriate text color for background */
.panel {
    background-color: var(--bg-secondary);
    color: var(--text-primary);
}

/* DON'T: Use primary text on primary background */
.panel {
    background-color: var(--bg-primary);
    color: var(--text-primary);  /* Not enough contrast! */
}
```

### Pattern 2: Interactive Elements

```css
/* DO: Use semantic colors for interactive states */
button {
    background-color: var(--bg-secondary);
    color: var(--text-primary);
}

button:hover {
    background-color: var(--interactive-hover-bg);
}

button:active {
    background-color: var(--interactive-active-bg);
    color: var(--interactive-active-fg);
}

button:focus-visible {
    outline: 2px solid var(--interactive-focus-outline);
}
```

### Pattern 3: Status Indicators

```css
/* DO: Use semantic status colors */
.alert-success { color: var(--color-success); }
.alert-warning { color: var(--color-warning); }
.alert-error { color: var(--color-error); }

/* DON'T: Use arbitrary colors */
.alert-success { color: #00FF00; }  /* May not work in all themes */
```

### Pattern 4: Borders & Dividers

```css
/* DO: Use accent-dim for subtle borders */
.divider {
    border-color: var(--accent-dim);
    border-width: 1px;
}

.input {
    border: 1px solid var(--accent-dim);
}

.input:focus {
    border-color: var(--accent-primary);
}
```

### Pattern 5: Transitions & Animations

```css
/* DO: Smooth transitions between states */
button {
    transition: background-color 150ms ease, color 150ms ease;
}

button:hover {
    background-color: var(--interactive-hover-bg);
}

/* DON'T: Jarring instant color changes */
button:hover {
    background-color: var(--interactive-hover-bg);
    /* no transition = bad UX */
}
```

---

## Palette-Specific Recommendations

### Light Themes (Rose Pine Dawn, Tokyo Night Day, Monokai Light)

| Element | Recommended | Why |
|---------|-------------|-----|
| Body text | --text-primary | Maximum contrast on light bg |
| Buttons | --accent-primary | Stands out on light |
| Links | --accent-primary | Standard link color |
| Borders | --accent-dim | Subtle on light bg |
| Disabled | --text-muted | Obvious but readable |

**Special Handling**:
- Be careful with very light text on light backgrounds
- Use --bg-secondary for contrast on primary
- Active states need careful color selection

### Dark Themes (Gruvbox Dark, Tokyo Night Night, Monokai Dark)

| Element | Recommended | Why |
|---------|-------------|-----|
| Body text | --text-primary | High contrast on dark |
| Buttons | --accent-primary | Bright on dark bg |
| Links | --accent-primary | Stands out |
| Borders | --accent-dim | Subtle on dark |
| Disabled | --text-muted | Visible but muted |

**Special Handling**:
- Accent colors work well on dark
- Use --bg-secondary for interactive elements
- Inverted colors (light text on dark bg) standard

### Medium Themes (Catppuccin Macchiato, Everforest Medium)

| Element | Recommended | Why |
|---------|-------------|-----|
| Body text | --text-primary | Balanced contrast |
| Buttons | --accent-primary | Good on medium |
| Links | --accent-secondary | Variation possible |
| Borders | --accent-dim | Appropriate |
| Disabled | --text-muted | Clear |

**Special Handling**:
- Most flexible for color choices
- Both light and dark text work
- Good for testing new patterns

---

## Accessibility Guidelines

### Keyboard Navigation

```css
/* MUST: Always show focus indicator */
element:focus-visible {
    outline: 2px solid var(--interactive-focus-outline);
    outline-offset: 1px;
}

/* DON'T: Hide focus indicators */
element:focus {
    outline: none;  /* Accessibility violation! */
}
```

### Color Alone Not Sufficient

```css
/* DO: Combine color with other indicators */
.status-success {
    color: var(--color-success);
    /* Also use icon or text */
}

/* DON'T: Rely only on color */
.status-success {
    color: var(--color-success);
    /* No visual indicator besides color */
}
```

### Contrast Validation

```bash
# Always check contrast ratios
python3 hack/audit-theme-contrast.py

# Or use online tool
# https://webaim.org/resources/contrastchecker/
```

---

## Customization Examples

### Example 1: Custom Button Style

```css
/* In your Firefox userChrome.css */
button.custom-button {
    background-color: var(--bg-secondary);
    color: var(--text-primary);
    border: 1px solid var(--accent-dim);
    padding: 8px 12px;
    border-radius: 4px;
    cursor: pointer;
    transition: all 150ms ease;
}

button.custom-button:hover {
    background-color: var(--interactive-hover-bg);
}

button.custom-button:active {
    background-color: var(--interactive-active-bg);
    color: var(--interactive-active-fg);
}

button.custom-button:focus-visible {
    outline: 2px solid var(--interactive-focus-outline);
    outline-offset: 2px;
}
```

### Example 2: Status Badge

```css
.badge {
    padding: 2px 8px;
    border-radius: 3px;
    font-size: 12px;
    font-weight: bold;
}

.badge-success {
    background-color: var(--color-success);
    color: var(--bg-primary);
}

.badge-warning {
    background-color: var(--color-warning);
    color: var(--bg-primary);
}

.badge-error {
    background-color: var(--color-error);
    color: var(--bg-primary);
}
```

### Example 3: Code Block

```css
pre {
    background-color: var(--bg-secondary);
    color: var(--text-primary);
    padding: 12px;
    border-radius: 4px;
    border-left: 3px solid var(--accent-primary);
    overflow-x: auto;
}

.token-keyword { color: var(--syntax-keyword); }
.token-string { color: var(--syntax-string); }
.token-number { color: var(--syntax-number); }
.token-comment { color: var(--syntax-comment); }
```

---

## Troubleshooting

### Colors Look Wrong

**Problem**: Colors don't match expected theme

**Solution**:
1. Verify CSS variables are being used (Inspector → Computed Styles)
2. Check for conflicting !important rules
3. Rebuild config: `task nix:refresh:lv426`
4. Clear browser cache (Cmd+Shift+Delete)

### Contrast Fails in One Theme

**Problem**: Specific palette has contrast issues

**Solution**:
1. Check contrast ratio: `python3 hack/audit-theme-contrast.py`
2. If below 4.5:1, may need palette adjustment
3. Document issue in GitHub issue
4. Consider using --text-secondary (lower contrast acceptable)

### Transitions Don't Work

**Problem**: CSS transitions not appearing

**Solution**:
1. Verify `transition:` property in CSS
2. Check browser console for CSS errors
3. May need to rebuild: `task nix:refresh:lv426`
4. Restart Firefox completely

### Variable Not Found

**Problem**: CSS variable not applying

**Solution**:
1. Check variable name spelling (case-sensitive)
2. Verify variable exists in :root
3. Check for typos in variable names
4. Use Inspector → Rules to see cascade

---

## Quick Reference Table

| Use Case | Variable | Fallback |
|----------|----------|----------|
| Main background | --bg-primary | #282828 |
| Secondary surface | --bg-secondary | #3c3836 |
| Body text | --text-primary | #f8f8f2 |
| Secondary text | --text-secondary | #a89984 |
| Muted text | --text-muted | #928374 |
| Interactive hover | --interactive-hover-bg | var(--accent-dim) |
| Interactive active | --interactive-active-bg | var(--accent-primary) |
| Link/button color | --accent-primary | #268bd2 |
| Border color | --accent-dim | #393552 |
| Success indicator | --color-success | #a6e22e |
| Warning indicator | --color-warning | #fabd2f |
| Error indicator | --color-error | #f92672 |

---

## Resources

- **WCAG 2.1 Contrast Requirements**: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum
- **Color Blindness Simulator**: https://www.color-blindness.com/coblis-color-blindness-simulator/
- **Contrast Checker**: https://webaim.org/resources/contrastchecker/
- **Accessible Colors**: https://accessible-colors.com/
- **CSS Variables Guide**: https://developer.mozilla.org/en-US/docs/Web/CSS/--*

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-20 | Initial color guide for Phase 4 |

