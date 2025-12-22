# Documentation Index

Complete guide to all planning and documentation in this repository.

---

## Quick Start for New Contributors

**New to this project?** Start here:

1. **README.md** - Project overview and philosophy
2. **AGENTS.md** - Available commands and quick reference
3. **MODULE_STRUCTURE.md** - How files are organized
4. **PLAN_QUICK_REFERENCE.md** - Which file does what

**Want to make a change?** Read:

1. **NIX_FILES_COMPREHENSIVE_PLAN.md** - Find your file's section
2. **PLAN_VISUAL_HIERARCHY.md** - Understand dependencies
3. The specific "Actions" and "Validation" from the plan

---

## Documentation by Purpose

### For Project Understanding

| Document | Purpose | Length | Time |
|---|---|---|---|
| **README.md** | Project philosophy, structure, technologies | ~200 lines | 10 min |
| **AGENTS.md** | Quick command reference | ~200 lines | 5 min |
| **MODULE_STRUCTURE.md** | Why files are organized this way | ~400 lines | 20 min |
| **AUDIT_SUMMARY.md** | Recent standardization work (Dec 21, 2025) | ~300 lines | 15 min |

### For Making Changes

| Document | Purpose | Length | Time |
|---|---|---|---|
| **NIX_FILES_COMPREHENSIVE_PLAN.md** | Every .nix file: what it does, how to change it | **1695 lines** | 60 min (full read) |
| **PLAN_QUICK_REFERENCE.md** | Quick lookup by file or category | ~400 lines | 20 min |
| **PLAN_VISUAL_HIERARCHY.md** | Dependencies and ripple effects | ~400 lines | 25 min |

---

## Documentation by Audience

### Project Owner (Rosh)

All docs are yours! Focus on:
1. **NIX_FILES_COMPREHENSIVE_PLAN.md** - Know what needs refactoring
2. **PLAN_VISUAL_HIERARCHY.md** - Understand system dependencies
3. **AUDIT_SUMMARY.md** - Track standardization progress

### Contributors

Read in this order:
1. README.md (what is this?)
2. MODULE_STRUCTURE.md (how is it organized?)
3. AGENTS.md (what commands are available?)
4. PLAN_QUICK_REFERENCE.md (what file do I need?)
5. NIX_FILES_COMPREHENSIVE_PLAN.md section for your file

### Other LLM Agents

You have everything you need:

**For understanding**: 
- README.md
- MODULE_STRUCTURE.md
- PLAN_VISUAL_HIERARCHY.md

**For making changes**:
- NIX_FILES_COMPREHENSIVE_PLAN.md (complete task reference)
- PLAN_QUICK_REFERENCE.md (quick lookup)
- AGENTS.md (available build commands)

**For validation**:
- Validation commands in NIX_FILES_COMPREHENSIVE_PLAN.md
- Build commands in AGENTS.md

---

## How to Use Each Document

### README.md
```
When to read: First time, before any code
What to learn: What this project does, high-level architecture
Action: Understand the 4-level system (flake → darwin/nixos/home → configs)
```

### AGENTS.md
```
When to read: Any time you need to run commands
What to learn: Available build, format, and testing tasks
Action: Use correct task for your work (task nix:build:lv426, task fmt:all, etc)
```

### MODULE_STRUCTURE.md
```
When to read: Before organizing new code or refactoring
What to learn: Why we use directories, impl.nix patterns, file naming
Action: Follow patterns shown in examples when creating new modules
```

### AUDIT_SUMMARY.md
```
When to read: To understand recent changes (commit b9ce215d1)
What to learn: What was standardized (lib.nix→impl.nix, etc)
Why it matters: Explains decisions made in recent refactoring
```

### NIX_FILES_COMPREHENSIVE_PLAN.md
```
When to read: Before making ANY change to a .nix file
How to use: Find your file in the document (search by name or section)
What you get: 
  - Current state description
  - List of specific actions to take
  - Validation commands to verify
  - Risk level (🔴/🟡/🟢)
  - Dependencies listed
What to do next: Follow the "Actions" section for your file
```

### PLAN_QUICK_REFERENCE.md
```
When to read: Need to quickly find a file or understand complexity
How to use: Search by filename, path, or category
What you get: Quick facts about each file
Find full details in: NIX_FILES_COMPREHENSIVE_PLAN.md
```

### PLAN_VISUAL_HIERARCHY.md
```
When to read: Before making changes that affect other parts
How to use: Find your file in the hierarchy, see what depends on it
What you learn: Ripple effects and safe change patterns
Questions answered:
  - "If I change X, what breaks?"
  - "Can I change A and B in parallel?"
  - "What MUST NEVER break?"
```

---

## Common Workflows

### Workflow: Add a New Package

**Documents to read**:
1. AGENTS.md - Check available tasks
2. PLAN_QUICK_REFERENCE.md - Find packages section
3. NIX_FILES_COMPREHENSIVE_PLAN.md - Home Manager Packages section

**Steps**:
1. Read: "Home Manager Packages (20 files)" in comprehensive plan
2. Identify: Which package manager (cargo, pip, npm, etc)
3. Edit: modules/home/packages/<manager>/default.nix
4. Add: Your package name to the list
5. Validate: Run command from plan
6. Test: `nix eval '.#homeConfigurations.*.config.home.packages'`

---

### Workflow: Fix a Broken Configuration

**Documents to read**:
1. NIX_FILES_COMPREHENSIVE_PLAN.md - Find your file
2. PLAN_VISUAL_HIERARCHY.md - Understand what it depends on
3. MODULE_STRUCTURE.md - Check naming patterns
4. AGENTS.md - Get build commands

**Steps**:
1. Identify: Which file is broken (from error message)
2. Find: That file in comprehensive plan
3. Read: "Actions" section for that file
4. Make: Changes following the actions
5. Validate: Run validation commands from plan
6. Build: Use appropriate task from AGENTS.md
7. Test: Follow "Validation" section completely

---

### Workflow: Refactor a Large File

**Documents to read**:
1. NIX_FILES_COMPREHENSIVE_PLAN.md - Your file's section
2. PLAN_VISUAL_HIERARCHY.md - What depends on it
3. MODULE_STRUCTURE.md - Patterns to follow
4. AGENTS.md - Build tasks

**Steps**:
1. Verify: Your file is marked with complexity level in plan
2. Read: Any "needs refactoring" notes in comprehensive plan
3. Design: How to split (reading "Actions" section)
4. Implement: Follow patterns from MODULE_STRUCTURE.md
5. Maintain: Imports in original file if splitting
6. Validate: Every validation command from plan
7. Build: Full build with AGENTS.md commands
8. Commit: Reference the plan in commit message

**Example task**:
```
REFACTOR: helix/default.nix
Reference: NIX_FILES_COMPREHENSIVE_PLAN.md → "helix/default.nix (735 lines)"
Current: One file, 735 lines
Target: Split into keybindings.nix, languages.nix, theme.nix, ui.nix
Validation: Test helix health and keybindings work
```

---

### Workflow: Update Theme or Colors

**Documents to read**:
1. NIX_FILES_COMPREHENSIVE_PLAN.md - "Shared Library" section, "Theme System"
2. PLAN_VISUAL_HIERARCHY.md - "Level 1" and "Change Ripple Effects"
3. PLAN_QUICK_REFERENCE.md - Theme files list

**Steps**:
1. Identify: Which theme palette or adapter to change
2. Edit: modules/shared/lib/theme/palettes/<theme>.nix (colors)
3. Or edit: modules/shared/lib/theme/adapters/<app>.nix (app-specific)
4. Test: `nix eval '.#utils.theme'`
5. Visual: Check each app that uses theme
6. Validate: All validation commands from plan
7. Build: Full build (theme changes affect everything)

---

### Workflow: Handoff to Another LLM

**Documents to give them**:
- [ ] This index (DOCUMENTATION_INDEX.md)
- [ ] Comprehensive plan (NIX_FILES_COMPREHENSIVE_PLAN.md)
- [ ] Quick reference (PLAN_QUICK_REFERENCE.md)
- [ ] Visual hierarchy (PLAN_VISUAL_HIERARCHY.md)
- [ ] Module structure (MODULE_STRUCTURE.md)
- [ ] AGENTS.md (build commands)
- [ ] Git repo with latest code

**How to frame the task**:
```
TASK: [Description]

CONTEXT FILES:
- Section in NIX_FILES_COMPREHENSIVE_PLAN.md: [Section name]
- Related files: [file1.nix, file2.nix]
- Risk level: [🔴 CRITICAL / 🟡 HIGH / 🟢 LOW]

ACTIONS REQUIRED:
[From the comprehensive plan's "Actions" section]

VALIDATION:
[From the comprehensive plan's "Validation" section]

EXPECTED OUTCOME:
[What success looks like]

TIME ESTIMATE:
[Hours]
```

---

## File Statistics

**Total Documentation**: 2969 lines across 5 files

| File | Lines | Purpose |
|---|---|---|
| NIX_FILES_COMPREHENSIVE_PLAN.md | 1695 | Complete file-by-file audit |
| PLAN_VISUAL_HIERARCHY.md | 600+ | Dependency mapping |
| PLAN_QUICK_REFERENCE.md | 400+ | Quick lookup |
| MODULE_STRUCTURE.md | 400+ | Architecture guide |
| AUDIT_SUMMARY.md | 300+ | Recent work summary |

**Project Code**: 182 .nix files, ~14,500 lines

---

## How to Keep Documentation Updated

### When Adding a New File
1. Add entry to NIX_FILES_COMPREHENSIVE_PLAN.md in appropriate section
2. Include: current state, actions, validation, risk level
3. Update PLAN_QUICK_REFERENCE.md "By File Location" section
4. Update PLAN_VISUAL_HIERARCHY.md if changing dependencies
5. Commit with reference to this documentation

### When Changing Structure
1. Update MODULE_STRUCTURE.md if pattern changes
2. Update NIX_FILES_COMPREHENSIVE_PLAN.md affected sections
3. Update PLAN_VISUAL_HIERARCHY.md if dependencies change
4. Commit message references: "Ref: NIX_FILES_COMPREHENSIVE_PLAN.md section X"

### When Standardizing Code
1. Add to AUDIT_SUMMARY.md "Completed" section
2. Update corresponding files in comprehensive plan
3. Note in commit message

### Before Handoff
1. Ensure all docs are up-to-date
2. Run: task nix:build:all (verify nothing broken)
3. Commit: any documentation updates
4. Provide: all 5 .md files to next LLM

---

## Documentation Maintenance Checklist

**Monthly**:
- [ ] Verify all file counts match actual files (182 in comprehensive plan)
- [ ] Check all validation commands still work
- [ ] Update AUDIT_SUMMARY.md with recent work

**When Making Large Changes**:
- [ ] Update affected sections in NIX_FILES_COMPREHENSIVE_PLAN.md
- [ ] Verify PLAN_VISUAL_HIERARCHY.md still accurate
- [ ] Check PLAN_QUICK_REFERENCE.md is current
- [ ] Update MODULE_STRUCTURE.md if patterns changed

**Before Handing Off**:
- [ ] Run full build: task nix:build:all
- [ ] Verify all validation commands in plan still work
- [ ] Check for any "TODO" or "FIXME" comments in docs
- [ ] Ensure no file references are broken
- [ ] Commit any final updates

---

## Quick Answers to Common Questions

### "Where should I add a new home-manager config?"
→ See NIX_FILES_COMPREHENSIVE_PLAN.md section "Home Manager Configurations"

### "What are the file naming conventions?"
→ See MODULE_STRUCTURE.md section "File Naming Conventions"

### "Is it safe to change X?"
→ See PLAN_VISUAL_HIERARCHY.md to find X and see what depends on it

### "How do I test my changes?"
→ Find your file in NIX_FILES_COMPREHENSIVE_PLAN.md, look for "Validation" section

### "What's the build command?"
→ See AGENTS.md section "Essential Commands"

### "What files are critical?"
→ See PLAN_VISUAL_HIERARCHY.md section "Files That Must NEVER Break"

### "Can I change A and B in parallel?"
→ See PLAN_VISUAL_HIERARCHY.md section "Safe Parallel Changes"

---

## Documentation Version History

| Date | Version | Changes | Commit |
|---|---|---|---|
| Dec 21, 2025 | 1.0 | Initial comprehensive documentation | ef1ee5604 |
| Dec 21, 2025 | - | Module standardization (lib.nix→impl.nix) | b9ce215d1 |

---

## Getting Help

**If you can't find something**:
1. Check PLAN_QUICK_REFERENCE.md by filename
2. Search NIX_FILES_COMPREHENSIVE_PLAN.md for key terms
3. Check PLAN_VISUAL_HIERARCHY.md for dependencies
4. Read AGENTS.md for available commands

**If documentation is outdated**:
1. Update the relevant .md file
2. Commit with message: "docs: update [section] per recent changes"
3. Note in commit: "Reference: NIX_FILES_COMPREHENSIVE_PLAN.md section X"

**If you find a mistake**:
1. Fix the documentation file
2. Commit with message: "docs: correct [what was wrong]"
3. No need to reference plan, just fix it

---

## Repository Structure Overview

```
.
├── README.md                           ← Start here!
├── AGENTS.md                           ← Commands
├── DOCUMENTATION_INDEX.md (this file)  ← You are here
│
├── Planning & Audit Documents:
├── NIX_FILES_COMPREHENSIVE_PLAN.md     ← Every .nix file (1695 lines)
├── PLAN_QUICK_REFERENCE.md            ← Quick lookup
├── PLAN_VISUAL_HIERARCHY.md           ← Dependencies
├── MODULE_STRUCTURE.md                ← Architecture
└── AUDIT_SUMMARY.md                   ← Recent work

└── Code:
    ├── flake.nix                       ← Root entry
    ├── flake/                          ← Flake config (6 files)
    ├── modules/
    │   ├── darwin/                     ← macOS (19 files)
    │   ├── nixos/                      ← Linux (38 files)
    │   ├── home/                       ← User config (96 files)
    │   └── shared/lib/                 ← Utilities (29 files)
    ├── overlays/                       ← Nix overrides (2 files)
    └── ... other files
```

---

## Final Notes

This documentation exists to:
1. **Enable self-service**: Contributors can find answers without asking
2. **Enable parallelization**: Multiple people can work on different parts safely
3. **Enable handoff**: New people (or LLMs) can understand the codebase immediately
4. **Reduce risk**: Clear actions and validations prevent breaking changes
5. **Track decisions**: AUDIT_SUMMARY.md explains the "why" behind patterns

If something is unclear in any document, that's a bug in the documentation.
Update it and commit the fix.

---

**Last updated**: Dec 21, 2025  
**Documentation version**: 1.0  
**Code base**: 182 .nix files, ~14,500 lines  
**Current commit**: ef1ee5604 (documentation), b9ce215d1 (recent standardization)
