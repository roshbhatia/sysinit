---
description: "Task list for theme configuration propagation implementation"
---

# Tasks: Theme Configuration Propagation

**Input**: Design documents from `/specs/002-theme-config-propagation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: No automated tests requested - validation via manual testing scenarios in quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Nix modules**: `modules/lib/theme/`, `modules/lib/values/`, `modules/lib/validation/`
- **Palette files**: `modules/lib/theme/palettes/*.nix`
- **Adapter files**: `modules/lib/theme/adapters/*.nix`
- **Application configs**: `modules/home/configurations/*/`
- **User config**: `values.nix`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and documentation updates

- [X] T001 Review current theme system structure and identify files requiring changes in modules/lib/theme/
- [X] T002 [P] Create backup branch before making changes via git branch theme-config-backup
- [X] T003 [P] Document current theme configuration behavior in specs/002-theme-config-propagation/IMPLEMENTATION.md

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core theme infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Add appearance field to theme values schema in modules/lib/values/default.nix (enum: "light" | "dark", default: "dark")
- [X] T005 [P] Add font configuration fields to theme values schema in modules/lib/values/default.nix (font.monospace, font.nerdfontFallback with defaults)
- [X] T006 Create theme validators in modules/lib/validation/default.nix (validateAppearanceMode, validatePaletteAppearance, validateFont)
- [X] T007 Update validateThemeConfig function in modules/lib/theme/default.nix to use new validators with clear error messages
- [X] T008 Add appearanceMapping to all palette meta sections in modules/lib/theme/palettes/*.nix (structure: `appearanceMapping = { light = "variant-name" | null; dark = "variant-name" | null; }` - see research.md Section 3 for palette-specific mappings)
- [X] T009 Test Nix evaluation succeeds with new schema via task nix:build

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Switch Light/Dark Mode (Priority: P1) 🎯 MVP

**Goal**: Enable users to switch between light and dark appearance modes with automatic variant mapping and build-time validation

**Independent Test**: Change appearance in values.nix, rebuild system, verify all applications (Wezterm, Neovim, Firefox) reflect the new appearance mode

### Implementation for User Story 1

- [X] T010 [P] [US1] Update Catppuccin palette in modules/lib/theme/palettes/catppuccin.nix with appearanceMapping (light: "latte", dark: "macchiato")
- [X] T011 [P] [US1] Update Rose Pine palette in modules/lib/theme/palettes/rose-pine.nix with appearanceMapping (light: "dawn", dark: "moon")
- [X] T012 [P] [US1] Update Gruvbox palette in modules/lib/theme/palettes/gruvbox.nix with appearanceMapping (light: "light", dark: "dark")
- [X] T013 [P] [US1] Update Solarized palette in modules/lib/theme/palettes/solarized.nix with appearanceMapping (light: "light", dark: "dark")
- [X] T014 [P] [US1] Update Kanagawa palette in modules/lib/theme/palettes/kanagawa.nix with appearanceMapping (light: null, dark: "wave")
- [X] T015 [P] [US1] Update Nord palette in modules/lib/theme/palettes/nord.nix with appearanceMapping (light: null, dark: "nord")
- [X] T016 [US1] Implement appearance-to-variant derivation logic in modules/lib/theme/default.nix (if user sets explicit variant use that; else derive from palette.meta.appearanceMapping[appearance] - see research.md Section 1 and data-model.md derivation strategy)
- [X] T017 [US1] Update Wezterm adapter in modules/lib/theme/adapters/wezterm.nix to include appearance field in generated JSON
- [X] T018 [US1] Update Neovim adapter in modules/lib/theme/adapters/neovim.nix to include appearance and background field in generated JSON
- [X] T019 [US1] Update Firefox adapter in modules/lib/theme/adapters/firefox.nix to include appearance field in generated JSON
- [X] T020 [US1] Test light mode with Gruvbox (Catppuccin latte not implemented yet) - appearance="light" correctly derives variant="light"
- [X] T021 [US1] Test dark mode with Rose Pine - appearance="dark" correctly derives variant="moon"
- [X] T022 [US1] Test invalid appearance + palette combination - appearance="light" + colorscheme="catppuccin" correctly fails with clear error

**Checkpoint**: At this point, User Story 1 should be fully functional - light/dark mode switching works across all applications

---

## Phase 4: User Story 2 - Change Color Palette (Priority: P2)

**Goal**: Enable users to switch between different color palettes with automatic appearance mode compatibility validation

**Independent Test**: Change colorscheme in values.nix, rebuild system, verify all applications adopt the new palette colors consistently

### Implementation for User Story 2

- [ ] T023 [P] [US2] Add palette compatibility check to validateThemeConfig in modules/lib/theme/default.nix (verify palette supports current appearance)
- [ ] T024 [P] [US2] Enhance error messages for palette validation in modules/lib/validation/default.nix (list available palettes for appearance mode)
- [ ] T025 [US2] Update Wezterm configuration in modules/home/configurations/wezterm/ to regenerate theme JSON on palette change
- [ ] T026 [US2] Update Neovim configuration in modules/home/configurations/neovim/ to regenerate theme JSON on palette change
- [ ] T027 [US2] Update Firefox configuration in modules/home/configurations/firefox/ to regenerate theme on palette change
- [ ] T028 [US2] Test palette switching with dark mode using quickstart.md Scenario 2 (Catppuccin → Rose Pine → Gruvbox)
- [ ] T029 [US2] Test palette switching with light mode using quickstart.md Scenario 2 (verify only palettes with light variants work)
- [ ] T030 [US2] Test multiple palette changes in sequence using quickstart.md Scenario 6 (5 consecutive palette/appearance changes)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - appearance mode and palette changes both function correctly

---

## Phase 5: User Story 3 - Change System Font (Priority: P3)

**Goal**: Enable users to switch monospace fonts with fallback chain for terminal and editor applications

**Independent Test**: Change font.monospace in values.nix, rebuild system, verify terminal and editor reflect the new font

### Implementation for User Story 3

- [ ] T031 [P] [US3] Update Wezterm adapter generateWeztermJSON in modules/lib/theme/adapters/wezterm.nix to include font configuration
- [ ] T032 [P] [US3] Update Neovim adapter generateNeovimJSON in modules/lib/theme/adapters/neovim.nix to include font configuration
- [ ] T033 [US3] Update Wezterm application config in modules/home/configurations/wezterm/wezterm.nix to read font from theme JSON
- [ ] T034 [US3] Update Neovim application config in modules/home/configurations/neovim/ to read font from theme JSON (if applicable)
- [ ] T035 [US3] Add font fallback chain logic to Wezterm config in modules/home/configurations/wezterm/wezterm.nix (monospace → nerdfontFallback → JetBrainsMono)
- [ ] T036 [US3] Test font switching using quickstart.md Scenario 3 (change to Fira Code Nerd Font, verify Wezterm and Neovim)
- [ ] T037 [US3] Test font fallback using quickstart.md Scenario 3 (use non-existent font, verify fallback to JetBrainsMono)
- [ ] T038 [US3] Test nerd font glyph rendering with quickstart.md validation checklist (verify icons display correctly)

**Checkpoint**: All user stories should now be independently functional - appearance, palette, and font all configurable

---

## Phase 6: Edge Cases & Validation

**Purpose**: Ensure robust error handling and validation for invalid configurations

- [ ] T039 [P] Add comprehensive error message template to validatePaletteAppearance in modules/lib/validation/default.nix (include field name, invalid value, available options)
- [ ] T040 [P] Test invalid appearance mode using quickstart.md Scenario 5a (expect: "appearance must be light or dark" error)
- [ ] T041 [P] Test invalid colorscheme using quickstart.md Scenario 5b (expect: "Theme not found" error with available list)
- [ ] T042 [P] Test invalid transparency opacity using quickstart.md Scenario 5c (expect: type or range validation error)
- [ ] T043 [P] Test empty font string using quickstart.md Scenario 5d (expect: "Font name cannot be empty" error)
- [ ] T044 Test palette missing light variant using quickstart.md Scenario 4 (expect: clear error with available palettes for light mode)
- [ ] T045 Verify all validation errors fail at Nix evaluation time before any system changes in quickstart.md edge cases

**Checkpoint**: All edge cases handled gracefully with clear error messages

---

## Phase 7: Integration & Stability

**Purpose**: Ensure theme changes are atomic, stable, and persistent across system restarts

- [ ] T046 Test atomic theme updates via Nix generation system (verify all apps update together or rollback works)
- [ ] T047 Test theme persistence across system restart using quickstart.md Scenario 7 (set theme, restart, verify unchanged)
- [ ] T048 Test rollback functionality via darwin-rebuild --rollback (verify previous theme restored to all apps)
- [ ] T049 [P] Verify theme JSON files generated in correct locations for all applications (~/.config/wezterm/theme.json, ~/.config/nvim/theme.json)
- [ ] T050 [P] Verify theme propagation to shell integrations (zsh/nu prompt colors match theme)
- [ ] T051 Run complete quickstart.md validation checklist (visual, file, build, rollback checks)
- [ ] T052 Test performance benchmarks from quickstart.md (build < 5s, activation < 30s)

**Checkpoint**: Theme system is stable, atomic, and persistent

---

## Phase 8: Documentation & Polish

**Purpose**: Update documentation and ensure maintainability

- [ ] T053 [P] Update README.md with new theme configuration options (appearance, font) via task docs:values
- [ ] T054 [P] Add theme configuration examples to README.md (minimal, light mode, full configuration)
- [ ] T055 [P] Document which palettes support light/dark modes in README.md or docs/
- [ ] T056 [P] Add troubleshooting section to README.md based on quickstart.md troubleshooting guide
- [ ] T057 Update CLAUDE.md to reflect theme configuration changes (if needed beyond automatic update)
- [ ] T058 [P] Format all modified Nix files via task fmt (nixfmt with 100-character width)
- [ ] T059 [P] Review and clean up any debug code or comments in modified files
- [ ] T060 Final validation: Run task nix:build && task nix:refresh with current values.nix
- [ ] T061 Create summary of changes in specs/002-theme-config-propagation/IMPLEMENTATION.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if multiple developers)
  - Or sequentially in priority order: US1 (P1) → US2 (P2) → US3 (P3)
- **Edge Cases (Phase 6)**: Can run in parallel with user stories or after
- **Integration (Phase 7)**: Depends on all user stories being complete
- **Documentation (Phase 8)**: Depends on all implementation complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Builds on US1 palette infrastructure but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Independent of US1/US2, only uses theme JSON generation

### Within Each User Story

**User Story 1**:
- T010-T015 (palette updates) can all run in parallel [P]
- T016 (derivation logic) depends on T010-T015 complete
- T017-T019 (adapter updates) can run in parallel after T016
- T020-T022 (testing) run sequentially after adapters updated

**User Story 2**:
- T023-T024 (validation) can run in parallel [P]
- T025-T027 (app configs) can run in parallel [P] after validation
- T028-T030 (testing) run sequentially after configs updated

**User Story 3**:
- T031-T032 (adapter updates) can run in parallel [P]
- T033-T035 (app configs) run after adapters updated
- T036-T038 (testing) run sequentially after configs updated

### Parallel Opportunities

- **Phase 1**: T002 and T003 can run in parallel [P]
- **Phase 2**: T005 and T008 can run in parallel [P] with other foundational tasks
- **Phase 3 (US1)**: T010-T015 all parallel [P], T017-T019 all parallel [P]
- **Phase 4 (US2)**: T023-T024 parallel [P], T025-T027 parallel [P]
- **Phase 5 (US3)**: T031-T032 parallel [P]
- **Phase 6**: T039-T043 all parallel [P]
- **Phase 7**: T049-T050 parallel [P]
- **Phase 8**: T053-T056, T058-T059 all parallel [P]
- **All three user stories can be worked on in parallel after Phase 2 completes**

---

## Parallel Example: User Story 1 (Light/Dark Mode)

```bash
# After Phase 2 completes, launch all palette updates together:
Task: "Update Catppuccin palette in modules/lib/theme/palettes/catppuccin.nix with appearanceMapping"
Task: "Update Rose Pine palette in modules/lib/theme/palettes/rose-pine.nix with appearanceMapping"
Task: "Update Gruvbox palette in modules/lib/theme/palettes/gruvbox.nix with appearanceMapping"
Task: "Update Solarized palette in modules/lib/theme/palettes/solarized.nix with appearanceMapping"
Task: "Update Kanagawa palette in modules/lib/theme/palettes/kanagawa.nix with appearanceMapping"
Task: "Update Nord palette in modules/lib/theme/palettes/nord.nix with appearanceMapping"

# After derivation logic (T016) complete, launch all adapter updates together:
Task: "Update Wezterm adapter in modules/lib/theme/adapters/wezterm.nix to include appearance field"
Task: "Update Neovim adapter in modules/lib/theme/adapters/neovim.nix to include appearance and background"
Task: "Update Firefox adapter in modules/lib/theme/adapters/firefox.nix to include appearance field"
```

---

## Parallel Example: User Story 2 (Color Palette)

```bash
# Launch validation and app config updates in parallel:
Task: "Add palette compatibility check to validateThemeConfig in modules/lib/theme/default.nix"
Task: "Enhance error messages for palette validation in modules/lib/validation/default.nix"

# Then launch all app configuration updates together:
Task: "Update Wezterm configuration in modules/home/configurations/wezterm/ to regenerate theme JSON"
Task: "Update Neovim configuration in modules/home/configurations/neovim/ to regenerate theme JSON"
Task: "Update Firefox configuration in modules/home/configurations/firefox/ to regenerate theme"
```

---

## Parallel Example: User Story 3 (System Font)

```bash
# Launch adapter updates together:
Task: "Update Wezterm adapter generateWeztermJSON in modules/lib/theme/adapters/wezterm.nix"
Task: "Update Neovim adapter generateNeovimJSON in modules/lib/theme/adapters/neovim.nix"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T009) - CRITICAL, blocks all stories
3. Complete Phase 3: User Story 1 (T010-T022)
4. **STOP and VALIDATE**: Test light/dark mode switching using quickstart.md Scenario 1
5. Demo/review if ready - this is a functional MVP!

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently with quickstart.md → **Deploy/Demo (MVP!)**
3. Add User Story 2 → Test independently with quickstart.md → Deploy/Demo
4. Add User Story 3 → Test independently with quickstart.md → Deploy/Demo
5. Add Edge Cases + Integration → Full stability validation
6. Add Documentation → Complete feature

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (Phase 1-2)
2. Once Foundational is done:
   - Developer A: User Story 1 (Light/Dark Mode) - T010-T022
   - Developer B: User Story 2 (Color Palette) - T023-T030
   - Developer C: User Story 3 (System Font) - T031-T038
3. Stories complete and integrate independently
4. Team reconvenes for Edge Cases, Integration, Documentation

---

## Summary Statistics

- **Total Tasks**: 61
- **Setup Phase**: 3 tasks
- **Foundational Phase**: 6 tasks (blocking)
- **User Story 1 (P1)**: 13 tasks
- **User Story 2 (P2)**: 8 tasks
- **User Story 3 (P3)**: 8 tasks
- **Edge Cases (Phase 6)**: 7 tasks
- **Integration (Phase 7)**: 7 tasks
- **Documentation (Phase 8)**: 9 tasks

**Parallel Opportunities**:
- 29 tasks marked [P] can run in parallel within their phase
- All 3 user stories can be worked on simultaneously after Foundational phase
- Each user story is independently testable using quickstart.md scenarios

**MVP Scope** (User Story 1 only):
- 22 tasks total (Setup + Foundational + US1)
- Delivers: Light/dark mode switching across all applications
- Estimated time: Smallest viable increment with immediate user value

**Independent Test Criteria**:
- **US1**: Change appearance mode → rebuild → verify all apps show new mode
- **US2**: Change palette → rebuild → verify all apps show new colors
- **US3**: Change font → rebuild → verify terminal/editor show new font

---

## Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label maps task to specific user story (US1, US2, US3) for traceability
- Each user story should be independently completable and testable per quickstart.md
- No automated tests - validation is manual via quickstart.md test scenarios
- Build-time validation ensures invalid configs fail before system changes
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Use `task nix:build` to validate, `task nix:refresh` to apply changes
- Use `darwin-rebuild --rollback` if anything breaks
- All file paths are absolute or relative to repository root
