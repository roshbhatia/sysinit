#!/usr/bin/env python3
"""
Ad-hoc theme contrast auditor.
Validates WCAG contrast ratios for theme palettes.
"""

import re
import sys
from typing import Tuple

def hex_to_rgb(hex_color: str) -> Tuple[int, int, int]:
    """Convert hex color to RGB."""
    hex_color = hex_color.lstrip('#')
    if len(hex_color) == 3:
        hex_color = ''.join([c*2 for c in hex_color])
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_luminance(rgb: Tuple[int, int, int]) -> float:
    """Calculate relative luminance (WCAG)."""
    r, g, b = [x / 255.0 for x in rgb]
    
    def channel(c):
        if c <= 0.03928:
            return c / 12.92
        return ((c + 0.055) / 1.055) ** 2.4
    
    r = channel(r)
    g = channel(g)
    b = channel(b)
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def contrast_ratio(color1: str, color2: str) -> float:
    """Calculate contrast ratio between two colors."""
    rgb1 = hex_to_rgb(color1)
    rgb2 = hex_to_rgb(color2)
    
    lum1 = rgb_to_luminance(rgb1)
    lum2 = rgb_to_luminance(rgb2)
    
    lighter = max(lum1, lum2)
    darker = min(lum1, lum2)
    
    return (lighter + 0.05) / (darker + 0.05)

def check_theme_contrast(theme_name: str, variant: str, text_color: str, bg_color: str) -> dict:
    """Check contrast for a theme variant."""
    ratio = contrast_ratio(text_color, bg_color)
    wcag_aa = ratio >= 4.5
    wcag_aaa = ratio >= 7.0
    
    return {
        'theme': theme_name,
        'variant': variant,
        'text': text_color,
        'bg': bg_color,
        'ratio': round(ratio, 2),
        'aa': wcag_aa,
        'aaa': wcag_aaa,
    }

def print_result(result: dict):
    """Print audit result."""
    status_aa = '✓ WCAG AA' if result['aa'] else '✗ WCAG AA'
    status_aaa = '✓ WCAG AAA' if result['aaa'] else '✗ WCAG AAA'
    
    print(f"{result['theme']:18} {result['variant']:16} {result['text']} on {result['bg']} = {result['ratio']} ({status_aa}, {status_aaa})")

# Test cases for existing themes
tests = [
    # Gruvbox
    ('Gruvbox', 'dark', '#ebdbb2', '#282828'),      # fg1 on bg
    ('Gruvbox', 'light', '#3c3836', '#fbf1c7'),     # fg1 on bg
    
    # Rose Pine
    ('Rose Pine', 'dawn', '#575279', '#faf4ed'),    # text on base
    ('Rose Pine', 'dawn', '#575279', '#fffaf3'),    # text on surface
    ('Rose Pine', 'moon', '#e0def4', '#232136'),    # text on base
    
    # Catppuccin
    ('Catppuccin', 'latte', '#4c4f69', '#eff1f5'),  # text on base
    ('Catppuccin', 'macchiato', '#cad3f5', '#24273a'), # text on base
    
    # Solarized
    ('Solarized', 'dark', '#839496', '#002b36'),    # text on base
    ('Solarized', 'light', '#073642', '#fdf6e3'),   # text on base (base02)
    
    # Nord
    ('Nord', 'dark', '#eceff4', '#2e3440'),         # text on base
    
    # Everforest
    ('Everforest', 'dark-hard', '#d3c6aa', '#272e33'),  # text on base
    ('Everforest', 'light-hard', '#5c6a72', '#fffbef'), # text on base
    
    # Kanagawa
    ('Kanagawa', 'lotus', '#545464', '#f2ecbc'),    # text on base
    ('Kanagawa', 'wave', '#dcd7ba', '#1f1f28'),     # text on base
    ('Kanagawa', 'dragon', '#c5c9c5', '#181616'),   # text on base
    
    # Black Metal
    ('Black Metal', 'gorgoroth', '#c1c1c1', '#000000'), # text on base
    
    # Tokyo Night
    ('Tokyonight', 'night', '#c0caf5', '#1a1b26'),     # text on base
    ('Tokyonight', 'storm', '#c0caf5', '#24283b'),     # text on base
    ('Tokyonight', 'day', '#3b3f5c', '#e1e2e7'),       # text on base
    
    # Monokai
    ('Monokai', 'dark', '#f8f8f2', '#272822'),          # text on base
    ('Monokai', 'light', '#272822', '#fafafa'),         # text on base
]

if __name__ == '__main__':
    print("\n=== THEME CONTRAST AUDIT ===\n")
    print(f"{'Theme':<18} {'Variant':<16} {'Text > Bg':<50} Contrast (WCAG)")
    print("-" * 100)
    
    failures = []
    for theme, variant, text, bg in tests:
        result = check_theme_contrast(theme, variant, text, bg)
        print_result(result)
        if not result['aa']:
            failures.append(result)
    
    print("\n" + "="*100)
    if failures:
        print(f"\n⚠ {len(failures)} WCAG AA VIOLATIONS:\n")
        for result in failures:
            print(f"  {result['theme']:18} {result['variant']:16} ratio={result['ratio']} (needs >= 4.5)")
    else:
        print("\n✓ All themes pass WCAG AA (4.5:1)")
    
    sys.exit(0 if not failures else 1)
