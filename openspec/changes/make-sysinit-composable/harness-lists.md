# Hand-kept harness lists

The enumeration task 4.4 requires. One `path:line` per list, with what the
list holds and why it qualifies.

A list qualifies when adding a harness requires editing it. A site that
branches on one harness name does not qualify, however many names it mentions.

Derived from the tree, not from a hand-written set. The starting command is the
one 4.4 names:

```
rg -n '"(claude|codex|opencode|crush|goose|gemini|cursor|devin|amp)"' modules/
```

It returns 127 matches across 31 files. That count is the reason for
enumerating rather than counting: most of those matches are per-harness files
naming themselves, and the command misses four lists that spell the names
without those quotes. The proposal estimated fourteen lists. There are fifteen.

## Qualifying: 15 lists

| # | Site | Holds | Names |
|---|---|---|---|
| 1 | `modules/home/programs/llm/harnesses/default.nix:2` | `imports`, one module path per harness | 11 |
| 2 | `modules/home/programs/llm/default.nix:168` | `harnessConfigNames` | 11 |
| 3 | `modules/home/programs/llm/lib/instructions.nix:16` | `harnessCoverage`, harness to confirmed context path | 11 |
| 4 | `modules/home/programs/llm/lib/instructions.nix:32` | `harnessesWithoutSkillLoader` | 1 |
| 5 | `modules/home/programs/llm/runtime/default.nix:8` | `svgs`, harness to icon file | 7 |
| 6 | `modules/home/programs/llm/runtime/default.nix:18` | `hookBridged` | 4 |
| 7 | `modules/home/programs/llm/runtime/default.nix:25` | `scrapeBridged` | 7 |
| 8 | `modules/home/programs/llm/runtime/default.nix:35` | `configuredHarnesses` | 11 |
| 9 | `modules/home/programs/llm/runtime/default.nix:51` | `bridgeArtifacts`, harness to bridge source | 2 |
| 10 | `modules/home/programs/llm/runtime/default.nix:79` | `intentionallyGeneric`, harnesses with no icon of their own | 4 |
| 11 | `modules/home/programs/llm/runtime/agent-notify.sh:44` | `case` mapping harness to display label | 10 |
| 12 | `modules/home/programs/llm/runtime/agent-prompt.sh:78` | `case` mapping harness to display label | 10 |
| 13 | `modules/home/programs/neovim/config/lua/harness/registry.lua:3` | `ORDER`, adapter load order | 12 |
| 14 | `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua:99` | `agents`, per-harness process detection patterns | 8 |
| 15 | `modules/home/packages.nix:143` | the harness CLI packages | 8 |

Lists 11 and 12 hold the same 10 pairs and neither cites the other.

List 13 disagrees with lists 2 and 8 on two names: it says `claudecode` where
they say `claude`, and `antigravity` where they say `gemini`. It also carries
`copilot` and `pi`, which list 14 does not.

List 15 holds package names rather than harness names (`amp-cli`,
`claude-agent-acp`, `cursor-cli`), so a registry entry has to carry the package
name separately from the harness name.

## Not qualifying

Each of these branches on one harness name. Adding a harness does not require
editing any of them.

- `modules/home/programs/llm/skills/render.nix:78`, `:165`, `:166`, `:192`,
  `:193` — `claude` and `amp` special cases in skill rendering
- `modules/home/programs/llm/lib/acp.nix:20`, `:25`, `:30` — the command each
  ACP server runs, inside that server's own attribute
- `modules/home/programs/llm/subagents/default.nix:65`, `:78` — `claude` and
  `opencode` special cases
- `modules/home/programs/llm/harnesses/pi/default.nix:75` — the pi bridge
  assertion
- `modules/home/programs/llm/lib/vocab.nix:4` — `claude` term overrides, with a
  `default` every other harness falls back to
- `modules/home/programs/neovim/config/lua/harness/sessions.lua:38`, `:60` —
  the `crush` and `goose` session-list commands
- `modules/home/programs/neovim/config/after/lsp/lsp_ai.lua:29`, `:54`, `:78`,
  `:81` — model names, which are not harness names
- `modules/home/programs/neovim/config/lua/plugins/gitsigns.lua`,
  `neoconf.lua`, `opencode.lua` — one name each
- `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua:1053` — the `codex`
  process aliases, inside that harness's own entry
- every file under `modules/home/programs/llm/harnesses/<name>/` and
  `modules/home/programs/neovim/config/lua/harness/adapters/<name>.lua` — a
  harness naming itself is not a list

## The assertions

These exist to police lists 2, 3, 6, 7, 8 and 9. Each compares two hand-kept
lists against each other, so a registry makes the property unrepresentable
rather than merely detected.

Deleted, as 4.4 asks:

- `modules/home/programs/llm/default.nix:190` — a harness config with no
  `harnessCoverage` entry
- `modules/home/programs/llm/default.nix:192` — a `harnessCoverage` entry with
  no harness config
- `modules/home/programs/llm/runtime/default.nix:73` — a configured harness
  that reaches no notifier
- `modules/home/programs/llm/runtime/default.nix:75` — a harness named as
  covered but not configured
- `modules/home/programs/llm/lib/instructions.nix:145` — a harness that renders
  context but is not declared in `harnessCoverage`
- `modules/home/programs/llm/harnesses/pi/default.nix:75` — the pi bridge not
  installed. It tested a literal attribute key against the literal set defined
  four lines below it, so it could not fail.

Deleted, and not named by 4.4:

- `modules/home/programs/llm/runtime/default.nix:99` — a harness in both `svgs`
  and `intentionallyGeneric`. One `ownIcon` boolean answers the question now,
  so a harness cannot be both.

Kept, against 4.4's instruction:

- `modules/home/programs/llm/runtime/default.nix:64` — a declared notify bridge
  whose file is missing or empty. This is the one assertion the registry cannot
  absorb. The others compare two lists, and one list cannot disagree with
  itself; this one compares a registry field against the filesystem, and a
  bridge file that is deleted or truncated still leaves that harness with no
  notifier at all. It now reads the registry and reports by harness name.
