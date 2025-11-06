# Implementation Tasks: Theme Configuration Audit & OpenCode Integration

**Branch**: `003-theme-audit` | **Date**: 2025-11-06
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Overview

This document provides a dependency-ordered task list for implementing the theme configuration audit and OpenCode integration feature. Tasks are organized by user story to enable independent implementation and testing.

**Total Tasks**: 22
**Estimated Completion**: 2-3 hours (configuration changes only, no new code)

## Implementation Strategy

**MVP Scope**: User Story 1 only (OpenCode theme integration)
- Minimum viable: Get OpenCode respecting system theme for 4/6 palettes
- Delivers immediate value: Theme consistency for primary development tool
- Independent: Can be tested and deployed without US2/US3

**Incremental Delivery**:
1. **Phase 3 (US1)**: OpenCode theme integration - testable independently
2. **Phase 4 (US2)**: Complete theme audit - builds on US1, validates all palettes
3. **Phase 5 (US3)**: Enhanced validation - adds tooling for ongoing maintenance

## Phase 1: Setup

**Goal**: Initialize validation and documentation directories

- [ ] T001 Create validation tests directory at specs/003-theme-audit/validation-tests/
- [ ] T002 Create documentation directory at specs/003-theme-audit/documentation/

**Duration**: 5 minutes

---

## Phase 2: Foundational

**Goal**: No foundational tasks required - all infrastructure exists in theme library

**Duration**: 0 minutes (skip to Phase 3)

---

## Phase 3: User Story 1 - OpenCode Reflects System Theme (P1)

**Story Goal**: Enable OpenCode to automatically match system theme settings (appearance mode + palette)

**Independent Test Criteria**:
- ✅ Build succeeds with theme library imported in opencode.nix
- ✅ `~/.config/opencode/opencode.json` contains theme field matching palette name (not "system")
- ✅ OpenCode launches with Catppuccin theme when `values.theme.colorscheme = "catppuccin"`
- ✅ Changing palette in values.nix + rebuild updates OpenCode theme

**Acceptance Scenarios**:
1. System set to dark mode + Catppuccin → OpenCode displays dark Catppuccin
2. System set to light mode + Gruvbox → OpenCode displays light Gruvbox (if supported)
3. Appearance mode change + rebuild → OpenCode switches theme variant

### Implementation Tasks

**Palette Adapters** (Parallel - different files):

- [ ] T003 [P] [US1] Add opencode adapter to Catppuccin palette in modules/lib/theme/palettes/catppuccin.nix
- [ ] T004 [P] [US1] Add opencode adapter to Gruvbox palette in modules/lib/theme/palettes/gruvbox.nix
- [ ] T005 [P] [US1] Add opencode adapter to Kanagawa palette in modules/lib/theme/palettes/kanagawa.nix
- [ ] T006 [P] [US1] Add opencode adapter to Nord palette in modules/lib/theme/palettes/nord.nix
- [ ] T007 [P] [US1] Add opencode adapter to Rose Pine palette (fallback to "system") in modules/lib/theme/palettes/rose-pine.nix
- [ ] T008 [P] [US1] Add opencode adapter to Solarized palette (fallback to "system") in modules/lib/theme/palettes/solarized.nix

**OpenCode Configuration** (Depends on T003-T008):

- [ ] T009 [US1] Update OpenCode config to import theme library in modules/home/configurations/llm/config/opencode.nix
- [ ] T010 [US1] Replace hardcoded "system" with getAppTheme call in modules/home/configurations/llm/config/opencode.nix

**Build Validation**:

- [ ] T011 [US1] Run `task nix:build` to verify configuration builds successfully
- [ ] T012 [US1] Run `task nix:refresh` to apply changes and deploy OpenCode config

**Manual Testing**:

- [ ] T013 [US1] Verify ~/.config/opencode/opencode.json contains correct theme field
- [ ] T014 [US1] Launch OpenCode and verify Catppuccin theme is displayed
- [ ] T015 [US1] Test theme switch by changing values.theme.colorscheme to "gruvbox" and rebuilding

**Duration**: 30-45 minutes

**Parallel Execution Example**:
```bash
# All palette adapters (T003-T008) can be modified simultaneously
# since they are independent files with no shared dependencies
```

---

## Phase 4: User Story 2 - All Themes Work Across All Applications (P1)

**Story Goal**: Verify all 6 palettes correctly theme all 12 configured applications

**Independent Test Criteria**:
- ✅ Each palette (Catppuccin, Rose Pine, Gruvbox, Solarized, Kanagawa, Nord) builds successfully
- ✅ Each palette applies correctly to: Wezterm, Neovim, Firefox, OpenCode, bat, delta, atuin, helix
- ✅ Invalid palette-variant combinations fail build with clear error messages
- ✅ All applications display consistent theming for each palette

**Acceptance Scenarios**:
1. Any palette selected → all applications apply theme correctly
2. Dark variant for any palette → all apps display correct dark colors
3. Light variant for supported palettes → all apps display correct light colors
4. Unsupported variant → build fails with clear error message

### Implementation Tasks

**Validation Script**:

- [ ] T016 [P] [US2] Create theme-audit.sh validation script in specs/003-theme-audit/validation-tests/theme-audit.sh
- [ ] T017 [US2] Implement palette adapter coverage check (iterate 6 palettes × 12 apps)
- [ ] T018 [US2] Add report generation for missing adapters in theme-audit.sh

**Manual Testing Matrix**:

- [ ] T019 [US2] Test Catppuccin palette across all applications (Wezterm, Neovim, Firefox, OpenCode, bat, delta, atuin, helix)
- [ ] T020 [US2] Test Rose Pine palette across all applications (verify "system" fallback in OpenCode)
- [ ] T021 [US2] Test Gruvbox palette with both dark and light variants across all applications
- [ ] T022 [US2] Test Solarized palette across all applications (verify "system" fallback in OpenCode)
- [ ] T023 [US2] Test Kanagawa palette across all applications
- [ ] T024 [US2] Test Nord palette across all applications

**Documentation**:

- [ ] T025 [US2] Create theme-support.md with compatibility matrix in specs/003-theme-audit/documentation/theme-support.md
- [ ] T026 [US2] Document manual testing procedure for each palette in theme-support.md
- [ ] T027 [US2] Document known limitations (OpenCode variant handling, Rose Pine/Solarized fallback) in theme-support.md
- [ ] T028 [US2] Document fallback behavior for unsupported palettes in theme-support.md

**Duration**: 60-90 minutes (mostly manual testing time)

**Parallel Execution Example**:
```bash
# T016-T018 (validation script) can be developed independently
# while T019-T024 (manual testing) proceeds in parallel
```

---

## Phase 5: User Story 3 - Theme Configuration Validation (P2)

**Story Goal**: Ensure comprehensive build-time validation catches configuration errors

**Independent Test Criteria**:
- ✅ Invalid palette name → build fails with available themes listed
- ✅ Invalid variant → build fails with valid variants listed
- ✅ Unsupported appearance mode → build fails with clear message
- ✅ Structural errors → build fails at evaluation time with location info

**Acceptance Scenarios**:
1. Invalid palette name → error lists available themes
2. Invalid variant → error shows valid variants for palette
3. Palette lacks variant → error indicates invalid combination
4. Structural error → error shows location and nature

### Implementation Tasks

**Validation Testing** (Intentional Failures):

- [ ] T029 [P] [US3] Test invalid palette name in values.nix (expect build failure with theme list)
- [ ] T030 [P] [US3] Test invalid variant in values.nix (expect build failure with variant list)
- [ ] T031 [P] [US3] Test unsupported appearance mode in values.nix (expect build failure with clear message)
- [ ] T032 [P] [US3] Document validation error messages in specs/003-theme-audit/documentation/theme-support.md

**Audit Script Execution**:

- [ ] T033 [US3] Run theme-audit.sh and verify all adapters present (expect 0 missing adapters)
- [ ] T034 [US3] Document audit script usage in specs/003-theme-audit/documentation/theme-support.md

**Duration**: 20-30 minutes

**Parallel Execution Example**:
```bash
# All validation tests (T029-T031) can run in parallel
# Each test is independent (different invalid config)
```

---

## Phase 6: Polish & Cross-Cutting Concerns

**Goal**: Format code, finalize documentation, verify completeness

- [ ] T035 Run `task fmt` to format all modified Nix files
- [ ] T036 Review all palette files for consistent opencode adapter format
- [ ] T037 Verify OpenCode config follows existing pattern from other app configs
- [ ] T038 Add completion notes to specs/003-theme-audit/documentation/theme-support.md
- [ ] T039 Update main CLAUDE.md if needed (already updated by agent context script)

**Duration**: 15 minutes

---

## Task Dependencies

### User Story Completion Order

```
Phase 1 (Setup)
    ↓
Phase 3 (US1 - OpenCode Integration) ← MVP SCOPE
    ↓
Phase 4 (US2 - Theme Audit) ← Depends on US1 (needs OpenCode adapters)
    ↓
Phase 5 (US3 - Validation) ← Depends on US2 (validates complete system)
    ↓
Phase 6 (Polish)
```

### Task Dependencies Within Phases

**Phase 3 (US1)**:
- T003-T008 (palette adapters) → T009-T010 (opencode config) → T011-T012 (build) → T013-T015 (testing)

**Phase 4 (US2)**:
- T016-T018 (validation script) [parallel with] T019-T024 (manual testing)
- T025-T028 (documentation) depends on test results

**Phase 5 (US3)**:
- T029-T032 (validation testing) → T033-T034 (audit execution + docs)

**Phase 6 (Polish)**:
- All previous phases complete → T035-T039 (sequential)

---

## Parallel Execution Opportunities

### Maximum Parallelism by Phase

**Phase 3 (US1)**: 6 parallel tasks
- T003, T004, T005, T006, T007, T008 (all palette adapters)

**Phase 4 (US2)**: 2 parallel streams
- Stream 1: T016-T018 (validation script development)
- Stream 2: T019-T024 (manual palette testing)

**Phase 5 (US3)**: 3 parallel tasks
- T029, T030, T031 (all validation tests)

---

## Testing Strategy

### Build-Time Testing (Automated)
- Nix evaluation validates structure at build time
- `validateThemeConfig` ensures valid palette/variant combinations
- `getAppTheme` ensures adapters exist for all applications

### Manual Testing (Required)
- Visual verification of theme application across all apps
- Follows quickstart.md testing procedures
- Uses theme-support.md testing checklist

### Validation Script (Semi-Automated)
- `theme-audit.sh` reports missing palette-app adapters
- Not a build failure, but documentation/coverage gap indicator

---

## Success Metrics

**User Story 1 (US1)**:
- ✅ OpenCode theme matches system theme for all 4 supported palettes
- ✅ Theme changes propagate to OpenCode after rebuild
- ✅ 2 fallback palettes use "system" theme correctly

**User Story 2 (US2)**:
- ✅ All 6 palettes theme all 12 applications correctly
- ✅ Zero runtime theme errors or mismatches
- ✅ Validation script reports 0 missing adapters

**User Story 3 (US3)**:
- ✅ 4 validation scenarios pass (invalid palette, variant, appearance, structure)
- ✅ All error messages are clear and actionable
- ✅ Documentation complete with compatibility matrix

---

## Time Estimates

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Setup | 5 min | 5 min |
| Phase 2: Foundational | 0 min | 5 min |
| Phase 3: US1 - OpenCode | 45 min | 50 min |
| Phase 4: US2 - Theme Audit | 90 min | 140 min |
| Phase 5: US3 - Validation | 30 min | 170 min |
| Phase 6: Polish | 15 min | 185 min |

**Total Estimated Time**: ~3 hours (2-3 hours with parallel execution)

**MVP Scope (US1 only)**: ~50 minutes

---

## Notes

- All file paths are absolute from repository root
- Tasks marked `[P]` are parallelizable with other `[P]` tasks in same phase
- Tasks marked `[US1]`, `[US2]`, `[US3]` belong to specific user stories
- Build-time validation already exists in theme library (no new validation code needed)
- Manual testing is required due to visual nature of theme verification
- Validation script (theme-audit.sh) is for documentation/coverage reporting, not CI/CD
