# Theme System Consolidation Plan

## Overview

This document outlines incremental steps to consolidate the theming system from 1,500 LOC to ~1,200 LOC (20% reduction) while improving maintainability.

**Goal**: Remove duplication, standardize patterns, improve clarity.

---

## Phase 1: Quick Wins (6 hours total)

### Task 1.1: Extract Adapter Base Class (2 hours)
**Current State**: 3 adapters with ~150 LOC of duplicated patterns
**Goal**: Create reusable base pattern for all adapters

#### Step 1: Create `core/adapter-base.nix`

```nix
# modules/lib/theme/core/adapter-base.nix
{ lib, utils }:

with lib;

{
  # Unified adapter creation pattern
  createAdapter = {
    appName,           # e.g. "neovim", "wezterm", "firefox"
    themeData,         # { palette, semanticColors, ... }
    colorMapping,      # app-specific color → semantic color mappings
    configBuilder,     # function(semanticColors, colorMapping) → app config
    jsonBuilder ? null, # optional: function to export as JSON
  }:
    let
      config = configBuilder themeData.semanticColors colorMapping;
      json = if jsonBuilder != null 
        then jsonBuilder config 
        else null;
    in
    {
      inherit config json;
      appName = appName;
      timestamp = builtins.now;
    };
  
  # Standard JSON export helper
  standardJsonExport = config: name: builtins.toJSON {
    name = name;
    type = "theme";
    config = config;
    generatedAt = builtins.now;
  };
  
  # Transparency application helper
  applyTransparency = {
    config,
    transparency,
    applyFn, # function that modifies config with transparency
  }:
    applyFn config transparency;
}
```

#### Step 2: Refactor `adapters/neovim.nix`

**Before** (133 lines):
```nix
{ lib, values, utils, ... }:
let
  theme = ...;
  palette = ...;
  semanticColors = ...;
  # ... 50 lines of setup ...
  config = {
    # ... app-specific config ...
  };
  json = builtins.toJSON {...};
in
{
  inherit config json;
}
```

**After** (30-40 lines):
```nix
{ lib, values, utils, adapterBase, ... }:
let
  theme = utils.getTheme values.theme.colorscheme;
  semanticColors = utils.getSemanticColors theme values;
  
  colorMapping = {
    # Neovim-specific semantic → color mappings
    "foreground.primary" = "text";
    "background.primary" = "bg";
    # ...
  };
  
  configBuilder = semanticColors: mapping:
    let
      mappedColors = lib.mapAttrs 
        (semantic: target: semanticColors.${target})
        mapping;
    in
    {
      # Neovim-specific config using mappedColors
      colorscheme = mappedColors;
      # ...
    };
in
adapterBase.createAdapter {
  appName = "neovim";
  themeData = { inherit semanticColors; };
  inherit colorMapping configBuilder;
  jsonBuilder = config: 
    adapterBase.standardJsonExport config "neovim-theme";
}
```

#### Step 3: Refactor `adapters/wezterm.nix` and `adapters/firefox.nix`
- Apply same pattern
- Move app-specific logic to `colorMapping` and `configBuilder`
- Use `standardJsonExport` for consistency

#### Files to Modify
- Create: `modules/lib/theme/core/adapter-base.nix`
- Modify: `modules/lib/theme/adapters/neovim.nix`
- Modify: `modules/lib/theme/adapters/wezterm.nix`
- Modify: `modules/lib/theme/adapters/firefox.nix`

#### Expected Outcome
- Remove 150 LOC of duplication
- Clearer intent (each adapter focuses on its mapping)
- Easier to add new adapters (copy-paste template)

---

### Task 1.2: Standardize Palette Keys (3 hours)

**Current State**: Each palette uses different color naming
- Some: `base`, `surface`, `overlay`
- Others: `bg0`, `bg1`, `base00`
- Fallback chains in semantic mapping are fragile

**Goal**: Normalize all palettes to standard key names

#### Step 1: Create Palette Normalizer in `core/palette-normalizer.nix`

```nix
# modules/lib/theme/core/palette-normalizer.nix
{ lib, utils }:

with lib;

{
  # Standard palette keys that all palettes must provide
  standardKeys = {
    # Base colors
    background = "primary background color";
    foreground = "primary foreground color";
    surface = "secondary background";
    overlay = "tertiary background";
    
    # Text colors (semantic)
    text = "main text";
    text_secondary = "secondary text";
    text_muted = "muted text";
    
    # Accents
    accent = "primary accent";
    accent_secondary = "secondary accent";
    accent_dim = "dimmed accent";
    
    # Semantic
    success = "success color";
    warning = "warning color";
    error = "error color";
    info = "info color";
  };
  
  # Define palette conversion map for legacy palettes
  conversionMaps = {
    catppuccin_macchiato = {
      base = "background";
      crust = "overlay";
      text = "text";
      subtext0 = "text_secondary";
      subtext1 = "text_muted";
      # ...
    };
    gruvbox = {
      bg0 = "background";
      bg1 = "surface";
      bg2 = "overlay";
      fg = "text";
      # ...
    };
    # ... more palettes ...
  };
  
  # Normalize a palette using conversion map
  normalizePalette = paletteId: palette:
    let
      conversion = conversionMaps.${paletteId} or {};
      normalized = lib.mapAttrs (oldKey: newKey:
        palette.${oldKey} or null
      ) conversion;
    in
    normalized // (builtins.removeAttrs palette (builtins.attrNames conversion));
  
  # Validate normalized palette has all standard keys
  validateNormalizedPalette = palette:
    let
      missingKeys = lib.filterAttrs (key: _:
        !(palette ? ${key})
      ) standardKeys;
    in
    if missingKeys != {} then
      throw "Palette missing keys: ${builtins.toJSON (builtins.attrNames missingKeys)}"
    else
      palette;
}
```

#### Step 2: Update All 8 Palettes
For each palette, create conversion map:
- `catppuccin.nix` - map macchiato keys to standard
- `gruvbox.nix` - map dark/light variants
- `kanagawa.nix` - map wave/dragon variants
- `rose-pine.nix` - map variants
- `solarized.nix` - map dark/light
- `nord.nix` - map keys
- `everforest.nix` - map variants
- `black-metal.nix` - map variants

#### Step 3: Update Semantic Mapping in `core/utils.nix`
Replace fragile fallback chains:
```nix
# Before:
safeGetColor palette key fallbacks =
  palette.${key} or 
  palette.${builtins.elemAt fallbacks 0} or
  palette.${builtins.elemAt fallbacks 1} or
  "#000000";

# After:
getColor normalizedPalette key =
  normalizedPalette.${key} or (
    throw "Required color ${key} not found in palette"
  );
```

#### Files to Modify
- Create: `modules/lib/theme/core/palette-normalizer.nix`
- Modify: All 8 `modules/lib/theme/palettes/*.nix`
- Modify: `modules/lib/theme/core/utils.nix` (createSemanticMapping)
- Modify: `modules/lib/theme/default.nix` (apply normalization)

#### Expected Outcome
- All palettes use consistent keys
- Semantic mapping becomes deterministic (no fallbacks)
- Reduces `utils.nix` from 433 to ~380 LOC
- Easier to understand color resolution

---

### Task 1.3: Consolidate Validation (1 hour)

**Current State**: Validation split across multiple places
- `core/types.nix` - type definitions
- `validation/default.nix` - external validation
- No exhaustive validation at construction time

**Goal**: Centralize all validation logic

#### Step 1: Create `core/validators.nix`

```nix
# modules/lib/theme/core/validators.nix
{ lib }:

with lib;

{
  validateColorValue = color:
    if utils.isValidHexColor color then
      color
    else
      throw "Invalid hex color: ${color}";
  
  validatePaletteId = id:
    if builtins.elem id [
      "catppuccin" "gruvbox" "kanagawa" "rose-pine"
      "solarized" "nord" "everforest" "black-metal"
    ] then
      id
    else
      throw "Unknown palette: ${id}";
  
  validateVariant = {paletteId, variant}:
    let
      validVariants = {
        catppuccin = ["latte" "frappe" "macchiato" "mocha"];
        gruvbox = ["dark" "light"];
        # ... full map ...
      };
    in
    if builtins.elem variant (validVariants.${paletteId} or []) then
      variant
    else
      throw "Invalid variant ${variant} for palette ${paletteId}";
  
  validateAppearance = appearance:
    if builtins.elem appearance ["light" "dark"] then
      appearance
    else
      throw "Invalid appearance: ${appearance}";
  
  validateTransparency = transparency:
    assert transparency.enable == true || transparency.enable == false;
    assert transparency.opacity >= 0 && transparency.opacity <= 1;
    assert transparency.blur >= 0;
    transparency;
  
  validateThemeConfig = config: {...};
}
```

#### Step 2: Update `core/types.nix`
Use validators with `types.apply`:
```nix
paletteIdType = types.str // {
  check = x: validators.validatePaletteId x;
};
```

#### Step 3: Remove External Validation
Clean up `validation/default.nix` to just import from theme

#### Files to Modify
- Create: `modules/lib/theme/core/validators.nix`
- Modify: `modules/lib/theme/core/types.nix`
- Modify: `validation/default.nix`

#### Expected Outcome
- Single source of truth for validation
- Validation happens at type level
- 30 LOC removed from validation module
- Clearer error messages

---

### Task 1.4: Consolidate Transparency (1 hour)

**Current State**: Transparency config spread across:
- `core/constants.nix` - preset definitions
- `presets/transparency.nix` - preset logic
- App adapters - preset application

**Goal**: Move all transparency logic to `core/presets.nix`

#### Step 1: Create `core/presets.nix`

```nix
# modules/lib/theme/core/presets.nix
{ lib }:

with lib;

let
  presetDefinitions = {
    # Standard presets
    none = {opacity = 1.0; blur = 0;};
    light = {opacity = 0.95; blur = 20;};
    medium = {opacity = 0.85; blur = 80;};
    heavy = {opacity = 0.70; blur = 120;};
    
    # Contextual presets
    coding = {opacity = 0.90; blur = 60;};
    reading = {opacity = 0.85; blur = 80;};
    presentation = {opacity = 1.0; blur = 0;};
    focus = {opacity = 0.95; blur = 40;};
  };
in

{
  inherit presetDefinitions;
  
  getPreset = presetName:
    presetDefinitions.${presetName} or 
    (throw "Unknown preset: ${presetName}");
  
  applyPreset = {config, presetName, applyFn}:
    let
      preset = getPreset presetName;
    in
    applyFn config preset;
  
  # Derive preset from appearance and context
  derivePreset = {appearance, context ? "default"}:
    if appearance == "presentation" then
      "presentation"
    else if context == "coding" then
      "coding"
    else if context == "reading" then
      "reading"
    else
      "medium";
}
```

#### Step 2: Update Adapters to Use Core Presets
Remove local preset logic, use `core/presets.nix`

#### Step 3: Remove `presets/transparency.nix`
(Or keep as deprecated wrapper for backwards compatibility)

#### Files to Modify
- Create: `modules/lib/theme/core/presets.nix`
- Modify: `modules/lib/theme/adapters/*.nix`
- Modify: `modules/lib/theme/default.nix`

#### Expected Outcome
- Single source for all presets
- Cleaner adapter code
- Better reusability

---

## Phase 2: Polish & Documentation (3 hours)

### Task 2.1: Semantic Layer Documentation (1 hour)

Create `docs/SEMANTIC_COLORS.md` documenting:
- All semantic color categories
- Which UI elements use which colors
- Color resolution algorithm
- Extension points for new semantics

### Task 2.2: Adapter Template (0.5 hours)

Create `adapters/TEMPLATE.nix` as example for new adapters

### Task 2.3: README Updates (1 hour)

Update `/modules/lib/theme/README.md`:
- Simplified architecture diagram
- Quick start guide
- Common customization patterns

### Task 2.4: Tests/Validation (0.5 hours)

Add simple validation tests in flake:
- Verify all palettes pass normalization
- Verify all adapters export valid JSON
- Verify semantic colors are complete

---

## Implementation Order

### Week 1: Phase 1
- **Mon**: Task 1.1 (Adapter base class) → PR
- **Tue**: Task 1.2 (Palette standardization) → PR
- **Wed**: Task 1.3 (Validation consolidation) → PR
- **Thu**: Task 1.4 (Transparency consolidation) → PR
- **Fri**: Integration testing

### Week 2: Phase 2
- **Mon-Tue**: Task 2.1 (Documentation)
- **Wed-Thu**: Task 2.2, 2.3, 2.4 (Templates & tests)
- **Fri**: Final review & publish

---

## Success Criteria

| Metric | Target | Current | Result |
|--------|--------|---------|--------|
| Total LOC | < 1,200 | 1,500 | 20% reduction |
| Adapter duplication | 0% | 40% | Eliminated |
| Palette consistency | 100% | 60% | Standardized |
| Lines per adapter | 30-40 | 100+ | Reduced |
| Type safety | Exhaustive | Partial | Complete |
| Documentation | Comprehensive | Minimal | Added |

---

## Rollback Plan

Each task is independent - if one goes wrong:
1. Revert that PR
2. Continue with others
3. Fix and retry in future phase

No blockers between tasks.

---

## Notes for Implementation

### Backwards Compatibility
- Keep old palette key names as aliases (initially)
- Deprecate in favor of normalized keys
- All app configs continue to work

### Testing Strategy
- Build theme system with new code
- Verify all 8 palettes normalize correctly
- Test all 3 adapters generate valid configs
- Check generated JSON format

### Code Review Checklist
- [ ] No duplication introduced
- [ ] Type safety improved
- [ ] Validation is exhaustive
- [ ] Documentation updated
- [ ] No breaking changes to adapters

---

## Future Improvements (Not in Scope)

1. **Palette Customization UI**: Allow users to tweak colors visually
2. **Color Math Library**: Extract color operations for external use
3. **Dark Mode Auto-Detection**: Automatically select variant based on OS
4. **Palette Generation**: Create palettes from seed colors
5. **Multi-Palette Blending**: Mix multiple palettes
