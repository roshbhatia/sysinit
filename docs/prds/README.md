# System Composability Refactor - PRDs

This directory contains Product Requirement Documents (PRDs) for refactoring the sysinit configuration to follow Unix philosophy principles with disposable Lima-based development environments.

## Quick Start

1. Read [00-overview.md](./00-overview.md) for the big picture
2. Follow PRDs sequentially: PRD-01 → PRD-02 → PRD-03 → PRD-04 → PRD-05 → PRD-06
3. Each PRD has explicit acceptance criteria and testing procedures
4. Tag git commits at safe points for easy rollback

## PRD Index

| PRD | Title | Status | Dependencies |
|-----|-------|--------|--------------|
| [00](./00-overview.md) | Overview | Reference | - |
| [01](./01-profile-system.md) | Profile System | Not Started | None |
| [02](./02-module-options.md) | Module Options | Not Started | PRD-01 |
| [03](./03-lima-foundation.md) | Lima Foundation | Not Started | PRD-01 |
| [04](./04-ghostty-zellij.md) | Ghostty + Zellij | Not Started | PRD-01, PRD-03 |
| [05](./05-project-vms.md) | Project VMs | Not Started | PRD-01, PRD-03, PRD-04 |
| [06](./06-minimal-host.md) | Minimal Host | Not Started | PRD-01, PRD-02, PRD-05 |

## Dependency Graph

```
PRD-01 (Profile System)
├─→ PRD-02 (Module Options)
│   └─→ PRD-06 (Minimal Host)
│
└─→ PRD-03 (Lima Foundation)
    └─→ PRD-04 (Ghostty + Zellij)
        └─→ PRD-05 (Project VMs)
            └─→ PRD-06 (Minimal Host)
```

## Critical Path

The fastest path to completion:
1. PRD-01: Profile System (foundation)
2. PRD-03: Lima Foundation (VM base)
3. PRD-04: Ghostty + Zellij (terminal/multiplexer)
4. PRD-05: Project VMs (tooling)
5. PRD-02: Module Options (cleanup)
6. PRD-06: Minimal Host (final cutover)

Alternatively, PRD-02 can be done in parallel with PRD-03/04/05.

## Document Structure

Each PRD follows this structure:

### Overview
What we're building and why it matters.

### Problem Statement
Current issues this PRD addresses.

### Proposed Solution
How we'll solve the problem.

### Scope
- **In Scope**: What's included
- **Out of Scope**: What's explicitly excluded

### Technical Design
- Architecture diagrams (Mermaid)
- File structure
- Code examples
- Integration points

### Acceptance Criteria
Explicit pass/fail conditions for PRD completion. No bolded lists, just clear criteria.

### Testing
Step-by-step testing procedures with expected outputs.

### Rollback
How to undo changes if something breaks.

### Dependencies
- **Blocks**: What depends on this PRD
- **Blocked By**: What this PRD depends on

### Notes
Additional context, gotchas, future considerations.

## Working with PRDs

### Before Starting a PRD

1. Read the PRD completely
2. Check dependencies are complete
3. Create git tag: `git tag pre-prd-<number>`
4. Create backup: `sudo tmutil localsnapshot /`

### While Working

1. Follow implementation steps in order
2. Test after each major change
3. Commit frequently with clear messages
4. Reference PRD in commit messages: "feat(PRD-01): add profile system"

### After Completing

1. Run all acceptance criteria tests
2. Verify no regressions
3. Commit with summary: "feat(PRD-01): complete profile system implementation"
4. Create tag: `git tag prd-01-complete`
5. Update status in this README

### If Something Breaks

1. Don't panic
2. Check the "Rollback" section in the PRD
3. Try rollback procedure
4. If rollback fails, use git tag to reset
5. If still broken, use Time Machine backup

## Success Metrics

Final success criteria for entire project:

- macOS host has < 100 packages (down from 200+)
- Lima VM starts in < 2 minutes
- `sysinit-vm shell` drops into working dev environment
- All existing workflows functional
- No manual setup for new projects
- Clean separation: host (desktop) vs VM (dev)

## Questions or Issues

- Check AGENTS.md for project conventions
- Check individual PRD "Notes" sections
- Open an issue or discussion if stuck
- Document learnings in .sysinit/lessons.md

## Rollback Safety

Safe rollback points (tag these):
- `pre-prd-01`: Before any changes
- `prd-01-complete`: After profile system works
- `prd-03-complete`: After Lima VMs work
- `prd-04-complete`: After Ghostty+Zellij work
- `prd-05-complete`: After project VMs work
- `prd-06-complete`: After minimal host (final)

To rollback:
```bash
git reset --hard <tag>
task nix:refresh:lv426
```
