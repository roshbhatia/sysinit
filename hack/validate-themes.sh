#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PALETTE_DIR="${SCRIPT_DIR}/../modules/shared/lib/theme/palettes"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
  echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

ERROR_COUNT=0
WARNING_COUNT=0

print_header "Theme Validation Script"
echo

REQUIRED_ADAPTERS=(
  "wezterm"
  "neovim"
  "bat"
  "delta"
  "atuin"
  "vivid"
  "helix"
  "k9s"
  "opencode"
  "sketchybar"
)

for palette_file in "${PALETTE_DIR}"/*.nix; do
  theme_name=$(basename "$palette_file" .nix)

  print_header "Validating theme: $theme_name"

  if [ ! -f "$palette_file" ]; then
    print_error "Palette file not found: $palette_file"
    ((ERROR_COUNT++))
    continue
  fi

  metadata=$(nix eval --impure --raw --expr "
    let
      lib = (import <nixpkgs> {}).lib;
      theme = import $palette_file { inherit lib; };
    in
      builtins.toJSON theme.meta
  " 2> /dev/null || echo "{}")

  if [ "$metadata" = "{}" ]; then
    print_error "Failed to read metadata for theme: $theme_name"
    ((ERROR_COUNT++))
    continue
  fi

  variants=$(echo "$metadata" | nix eval --impure --expr "builtins.fromJSON (builtins.readFile /dev/stdin)" --apply 'x: builtins.toJSON x.variants' 2> /dev/null || echo "[]")
  supports=$(echo "$metadata" | nix eval --impure --expr "builtins.fromJSON (builtins.readFile /dev/stdin)" --apply 'x: builtins.toJSON x.supports' 2> /dev/null || echo "[]")

  print_success "Found variants: $(echo "$variants" | tr -d '[]"' | tr ',' ' ')"
  print_success "Supports modes: $(echo "$supports" | tr -d '[]"' | tr ',' ' ')"

  if echo "$supports" | grep -q '"light"'; then
    light_variant=$(nix eval --impure --raw --expr "
      let
        lib = (import <nixpkgs> {}).lib;
        theme = import $palette_file { inherit lib; };
      in
        if theme.meta.appearanceMapping.light != null 
        then theme.meta.appearanceMapping.light 
        else \"null\"
    " 2> /dev/null || echo "null")

    if [ "$light_variant" = "null" ]; then
      print_error "Theme claims light support but appearanceMapping.light is null"
      ((ERROR_COUNT++))
    else
      has_light_palette=$(nix eval --impure --expr "
        let
          lib = (import <nixpkgs> {}).lib;
          theme = import $palette_file { inherit lib; };
        in
          builtins.hasAttr \"$light_variant\" theme.palettes
      " 2> /dev/null || echo "false")

      if [ "$has_light_palette" = "false" ]; then
        print_error "Light variant '$light_variant' defined in appearanceMapping but palette missing"
        ((ERROR_COUNT++))
      else
        print_success "Light variant '$light_variant' palette exists"
      fi
    fi
  fi

  if echo "$supports" | grep -q '"dark"'; then
    dark_variant=$(nix eval --impure --raw --expr "
      let
        lib = (import <nixpkgs> {}).lib;
        theme = import $palette_file { inherit lib; };
      in
        if theme.meta.appearanceMapping.dark != null 
        then theme.meta.appearanceMapping.dark 
        else \"null\"
    " 2> /dev/null || echo "null")

    if [ "$dark_variant" = "null" ]; then
      print_error "Theme claims dark support but appearanceMapping.dark is null"
      ((ERROR_COUNT++))
    else
      has_dark_palette=$(nix eval --impure --expr "
        let
          lib = (import <nixpkgs> {}).lib;
          theme = import $palette_file { inherit lib; };
        in
          builtins.hasAttr \"$dark_variant\" theme.palettes
      " 2> /dev/null || echo "false")

      if [ "$has_dark_palette" = "false" ]; then
        print_error "Dark variant '$dark_variant' defined in appearanceMapping but palette missing"
        ((ERROR_COUNT++))
      else
        print_success "Dark variant '$dark_variant' palette exists"
      fi
    fi
  fi

  for adapter in "${REQUIRED_ADAPTERS[@]}"; do
    has_adapter=$(nix eval --impure --expr "
      let
        lib = (import <nixpkgs> {}).lib;
        theme = import $palette_file { inherit lib; };
      in
        builtins.hasAttr \"$adapter\" theme.appAdapters
    " 2> /dev/null || echo "false")

    if [ "$has_adapter" = "false" ]; then
      print_warning "Missing adapter: $adapter"
      ((WARNING_COUNT++))
    fi
  done

  echo
done

print_header "Validation Summary"
echo

if [ $ERROR_COUNT -eq 0 ]; then
  print_success "All critical validations passed!"
else
  print_error "Found $ERROR_COUNT error(s)"
fi

if [ $WARNING_COUNT -gt 0 ]; then
  print_warning "Found $WARNING_COUNT warning(s)"
fi

echo

if [ $ERROR_COUNT -gt 0 ]; then
  exit 1
fi

exit 0
