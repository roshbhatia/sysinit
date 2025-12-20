#!/usr/bin/env bash

# hack/generate-theme-docs.sh
# Generate documentation for available themes from palette definitions
# Extracts theme metadata and creates a comprehensive theme reference

set -euo pipefail

README_FILE="${1:-README.md}"
THEME_DIR="modules/shared/lib/theme/palettes"
START_MARKER="<!-- THEME_DOCS_START -->"
END_MARKER="<!-- THEME_DOCS_END -->"

TEMP_FILE=$(mktemp)

cat > "$TEMP_FILE" << 'EOF'

| Theme | ID | Variants | Light Mode | Dark Mode | Author |
|-------|----|---------:|:----------:|:---------:|--------|
EOF

echo "Parsing theme metadata from $THEME_DIR..." >&2

for theme_file in "$THEME_DIR"/*.nix; do
  theme_basename=$(basename "$theme_file" .nix)

  theme_name=$(grep -m 1 'name = "' "$theme_file" | sed 's/.*name = "\([^"]*\)".*/\1/' || echo "$theme_basename")
  theme_id=$(grep -m 1 'id = "' "$theme_file" | sed 's/.*id = "\([^"]*\)".*/\1/' || echo "$theme_basename")

  variants_raw=$(awk '/variants = \[/,/\];/' "$theme_file" | grep '"' | sed 's/.*"\([^"]*\)".*/\1/')
  variants=$(echo "$variants_raw" | tr '\n' ', ' | sed 's/,$//' | sed 's/,/, /g')
  variant_count=$(echo "$variants_raw" | wc -l | tr -d ' ')

  supports_light="❌"
  supports_dark="❌"

  if grep -q 'supports = \[' "$theme_file"; then
    if awk '/supports = \[/,/\];/' "$theme_file" | grep -q '"light"'; then
      supports_light="✅"
    fi
    if awk '/supports = \[/,/\];/' "$theme_file" | grep -q '"dark"'; then
      supports_dark="✅"
    fi
  fi

  author=$(grep -m 1 'author = "' "$theme_file" | sed 's/.*author = "\([^"]*\)".*/\1/' || echo "Unknown")
  homepage=$(grep -m 1 'homepage = "' "$theme_file" | sed 's/.*homepage = "\([^"]*\)".*/\1/' || echo "")

  if [[ -n $homepage ]]; then
    author_link="[$author]($homepage)"
  else
    author_link="$author"
  fi

  echo "| $theme_name | \`$theme_id\` | $variant_count ($variants) | $supports_light | $supports_dark | $author_link |" >> "$TEMP_FILE"
done

cat >> "$TEMP_FILE" << 'EOF'

### Usage

To use a theme, set the following in your `values.nix`:

```nix
{
  theme = {
    colorscheme = "theme-id";  # Use ID from table above
    variant = "variant-name";   # Use one of the available variants
    appearance = "dark";        # or "light" - auto-selects appropriate variant
  };
}
```

### Theme Variant Selection

The theme system supports both explicit variant selection and automatic appearance-based selection:

- **Explicit**: Set `variant` to a specific variant name (e.g., `"macchiato"`, `"moon"`)
- **Automatic**: Set `appearance` to `"light"` or `"dark"` and the system will choose an appropriate variant

Example configurations:

```nix
# Explicit variant selection
theme = {
  colorscheme = "catppuccin";
  variant = "macchiato";
};

# Automatic appearance-based selection
theme = {
  colorscheme = "gruvbox";
  appearance = "dark";  # Automatically selects "dark" variant
};

# Appearance-based with variant preference
theme = {
  colorscheme = "everforest";
  appearance = "dark";
  variant = "dark-soft";  # Prefers this variant if compatible with appearance
};
```
EOF

if [[ -f $README_FILE ]]; then
  if grep -q "$START_MARKER" "$README_FILE" && grep -q "$END_MARKER" "$README_FILE"; then
    awk -v start="$START_MARKER" -v end="$END_MARKER" '
      BEGIN { in_section=0; printed_new=0 }
      $0 == start {
        print $0
        while ((getline line < "'"$TEMP_FILE"'") > 0) print line
        close("'"$TEMP_FILE"'")
        in_section=1
        printed_new=1
        next
      }
      $0 == end {
        print $0
        in_section=0
        next
      }
      !in_section { print $0 }
    ' "$README_FILE" > "${README_FILE}.tmp"

    mv "${README_FILE}.tmp" "$README_FILE"
    echo "Theme documentation injected into $README_FILE" >&2
  else
    echo "Warning: Markers not found in $README_FILE. Add the following markers where you want the documentation:" >&2
    echo "  $START_MARKER" >&2
    echo "  $END_MARKER" >&2
    exit 1
  fi
else
  echo "Error: $README_FILE not found" >&2
  exit 1
fi

rm -f "$TEMP_FILE"
echo "Theme documentation generation complete!" >&2
