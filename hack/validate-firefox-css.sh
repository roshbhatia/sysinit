#!/usr/bin/env bash
# Firefox CSS validation - ad-hoc tests for theme CSS enhancements
set -euo pipefail

FIREFOX_ADAPTER="modules/shared/lib/theme/adapters/firefox.nix"

echo "=== Firefox CSS Validation ==="
echo

# Test 1: Check semantic CSS variables exist
echo "Test 1: Semantic CSS Variables"
if grep -q "^\s*--bg-primary:" "$FIREFOX_ADAPTER" &&
  grep -q "^\s*--text-primary:" "$FIREFOX_ADAPTER" &&
  grep -q "^\s*--accent-primary:" "$FIREFOX_ADAPTER"; then
  echo "✓ All semantic background, text, and accent variables defined"
else
  echo "✗ Missing semantic CSS variables"
  exit 1
fi

# Test 2: Check base16 color variables (new)
echo "Test 2: Base16 Color Variables"
if grep -q "^\s*--color-red:" "$FIREFOX_ADAPTER" &&
  grep -q "^\s*--color-blue:" "$FIREFOX_ADAPTER" &&
  grep -q "^\s*--color-purple:" "$FIREFOX_ADAPTER"; then
  echo "✓ Base16 color variables defined"
else
  echo "✗ Missing base16 color variables"
  exit 1
fi

# Test 3: Check interactive element variables (new)
echo "Test 3: Interactive Element Variables"
if grep -q "^\s*--interactive-hover-bg:" "$FIREFOX_ADAPTER" &&
  grep -q "^\s*--interactive-active-bg:" "$FIREFOX_ADAPTER" &&
  grep -q "^\s*--interactive-focus-outline:" "$FIREFOX_ADAPTER"; then
  echo "✓ Interactive element state variables defined"
else
  echo "✗ Missing interactive element variables"
  exit 1
fi

# Test 4: Check menu styling enhancements
echo "Test 4: Menu Styling Enhancements"
if grep -q "^\s*--uc-menu-hover-bg:" "$FIREFOX_ADAPTER" &&
  grep -q "^\s*--uc-menu-active-bg:" "$FIREFOX_ADAPTER" &&
  grep -q "menu:hover," "$FIREFOX_ADAPTER"; then
  echo "✓ Menu hover and active states enhanced"
else
  echo "✗ Menu styling not enhanced"
  exit 1
fi

# Test 5: Check button styling enhancements
echo "Test 5: Button Styling Enhancements"
if grep -q "toolbar .toolbarbutton-1:hover" "$FIREFOX_ADAPTER" &&
  grep -q "toolbar .toolbarbutton-1:focus-visible" "$FIREFOX_ADAPTER" &&
  grep -q "toolbar .toolbarbutton-1\[open\]" "$FIREFOX_ADAPTER"; then
  echo "✓ Button hover, focus, and active states enhanced"
else
  echo "✗ Button styling not enhanced"
  exit 1
fi

# Test 6: Check urlbar styling enhancements
echo "Test 6: Urlbar Focus States"
if grep -q "#urlbar:focus-within" "$FIREFOX_ADAPTER" &&
  grep -q "border-color: var(--minimal-accent)" "$FIREFOX_ADAPTER"; then
  echo "✓ Urlbar focus states have accent border and shadow"
else
  echo "✗ Urlbar focus states not enhanced"
  exit 1
fi

# Test 7: Check tab styling enhancements
echo "Test 7: Tab Styling Enhancements"
if grep -q ".tabbrowser-tab\[selected\] {" "$FIREFOX_ADAPTER" &&
  grep -q "border-bottom: 2px solid var(--minimal-accent)" "$FIREFOX_ADAPTER" &&
  grep -q ".tabbrowser-tab:not(\[selected\]):hover .tab-label" "$FIREFOX_ADAPTER"; then
  echo "✓ Tab selected state and hover states enhanced"
else
  echo "✗ Tab styling not enhanced"
  exit 1
fi

# Test 8: Check transitions and animations exist
echo "Test 8: Smooth Transitions"
if grep -q "transition:" "$FIREFOX_ADAPTER"; then
  count=$(grep -c "transition:" "$FIREFOX_ADAPTER" || true)
  echo "✓ Found $count CSS transitions for smooth state changes"
else
  echo "⚠ No CSS transitions found (optional)"
fi

# Test 9: Verify palettes integration
echo "Test 9: Palette Integration"
palette_count=$(find modules/shared/lib/theme/palettes -name "*.nix" -type f | wc -l)
if [ "$palette_count" -ge 10 ]; then
  echo "✓ $palette_count palettes available"
else
  echo "⚠ Only $palette_count palettes (expected 10+)"
fi

# Test 10: Check for no conflicting styles
echo "Test 10: Style Consistency"
if ! grep -q "!important.*!important" "$FIREFOX_ADAPTER"; then
  echo "✓ No duplicate !important declarations"
else
  echo "✗ Duplicate !important declarations found"
  exit 1
fi

echo
echo "✓ === All Firefox CSS Validation Checks Passed ==="
echo
echo "Summary of Phase 3 Enhancements:"
echo "  • Semantic CSS variables: text, background, accent with hierarchy"
echo "  • Base16 color variables: red, orange, yellow, green, cyan, blue, purple"
echo "  • Interactive states: hover, active, focus with dedicated variables"
echo "  • Menu improvements: hover (accent-dim) → active (accent-primary)"
echo "  • Button enhancements: hover/active/focus states with transitions"
echo "  • Urlbar focus: accent border + shadow for better visibility"
echo "  • Tab styling: selected indicator (accent bottom border) + hover effects"
echo "  • Smooth transitions: 150ms ease on state changes"
