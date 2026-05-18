## Context

This change extends two patterns already established in the repo:

- **Slim Python-CLI overlay** at `overlays/cocoindex-code.nix`: pure-Python
  `buildPythonApplication` from a PyPI sdist, hand-pinned with `fetchurl` +
  `sha256`, optional extras deliberately omitted, runtime configuration left
  to the user. `cocoindex-code`'s `ccc init` flow is the direct precedent
  for `hermes setup` here.
- **`wrapProgram` for binary discovery** is used throughout nixpkgs derivations
  for tools that shell out to other binaries (the closest in-repo analogue
  is `overlays/openspec.nix`'s `makeWrapper` invocation). The hermes overlay
  uses the same primitive to prepend its subagent binaries onto `PATH`.

There is no existing Nix packaging of `hermes-agent` (verified by inspecting
nixpkgs master, NUR, and the upstream repo at
https://github.com/NousResearch/hermes-agent — no `flake.nix`, no nixpkgs
PR). This change is the first packaging.

Constraints in scope:

- Apple Silicon (`aarch64-darwin`) is the primary target. Linux platforms
  ship as a side effect of the slim build; no platform-specific code paths.
- `nixpkgs-unstable` is the source of truth for transitive Python
  dependencies. The hermes pyproject pins core deps to exact versions
  (`openai==2.24.0`, `httpx==0.28.1`, `pydantic==2.12.5`, etc.) explicitly
  to harden against supply-chain compromise. Nixpkgs may carry newer
  versions; we accept the divergence rather than vendor older pins.
- The user already has `claude-code`, `codex-acp`, `opencode`,
  `github-copilot-cli`, `gh`, and `gemini` in their package set via
  `modules/home/packages.nix`. The wrapProgram step is a *belt-and-suspenders*
  guarantee, not a backstop for missing tooling.

## Goals / Non-Goals

**Goals:**

- Single declarative path to `hermes` on every host (`nh os switch` and
  the binary is in `$PATH`).
- Build-time guarantee that the autonomous-AI-agents bundled skills find
  `claude-code`, `codex`, and `opencode` on `PATH`, even from a minimal
  shell (e.g. inside another agent's subprocess invocation).
- Build-time guarantee that the GitHub Copilot ACP provider finds the
  `copilot` binary.
- Zero coupling to external services in the build closure: no API keys
  baked in, no provider state in `/etc/`, no daemon registration.
- Closure size comparable to `cocoindex-code` (small Python wrapper + core
  deps; no torch, no Chromium, no node_modules).

**Non-Goals:**

- Declarative management of `~/.hermes/` — see proposal Non-goals.
- Bundling messaging integrations (WhatsApp, Telegram, Discord, Slack) or
  browser automation (Playwright). The Node.js v22 dependency chain is out
  of scope.
- Wiring hermes into the existing MCP server registry. Hermes is a peer
  harness, not an MCP tool consumed by Claude Code.
- Pre-flighting `copilot login` or any other interactive auth flow during
  build or activation. Auth is user-driven, one-time-per-machine, at
  runtime.
- Locking the hermes version against a curated set of providers. Upstream
  provider support is broad and evolves; we bind `hermes-agent==0.14.0`
  and let the user choose providers at runtime.

## Decisions

**1. Slim overlay with zero Python extras.**

The pyproject ships extras for `anthropic`, `exa`, `firecrawl`, `fal`,
`edge-tts`, `modal`, `daytona`, `parallel-web`, and `aws` (boto3). The
upstream provider matrix
(https://hermes-agent.nousresearch.com/docs/integrations/providers) shows
that every provider the user has named — `anthropic` (direct), `gemini`,
`google-gemini-cli`, `copilot`, `copilot-acp`, plus optional `openrouter`,
`xai` — works *without* any of these extras. The `[anthropic]` extra ships
`anthropic==0.86.0` (a very old SDK release) for a separate code path not
exercised by the native `anthropic` provider, which talks HTTP via the
core `httpx` dependency.

*Alternatives considered:*

- **Include `[anthropic]` extra by default**: rejected because the pinned
  SDK is old, the native provider doesn't need it, and adding it would
  drag a stale Anthropic SDK into the closure for zero current benefit.
  Re-evaluate only if Nous makes the SDK extra mandatory for a provider
  the user actually uses.
- **Include all extras (`pip install hermes-agent[all]`)**: rejected
  because it bloats the closure with `exa-py`, `firecrawl-py`,
  `fal-client`, `parallel-web`, etc. — services the user has no stated
  interest in, each with its own dependency surface.
- **Include only `[aws]` for Bedrock**: rejected because Bedrock is not
  in the user's provider plan. If added later, it's a single-line overlay
  change.

**2. `wrapProgram` with explicit subagent PATH.**

The wrapper prepends `${claude-code}/bin`, `${codex-acp}/bin`,
`${opencode}/bin`, `${github-copilot-cli}/bin` (provides `copilot`),
`${gh}/bin`, and `${gemini}/bin` (or equivalent attribute names — verified
at build time against `final` overlay) onto `PATH`. This means a
`hermes` process spawned from a minimal environment still finds every
subagent binary the bundled skills depend on.

*Alternatives considered:*

- **Document expected PATH without wrapping**: rejected because the
  failure mode (skill silently can't find its subagent) is invisible until
  runtime, by which point the user has lost context on what's missing.
  wrapProgram converts a runtime failure into a build-time guarantee.
- **Wrap with `--suffix` instead of `--prefix`**: rejected because if the
  user has a custom build of, say, `claude-code` ahead of the Nix one
  earlier in `PATH`, the suffix would let the user override. That's the
  user's choice — but for the *default* path the in-repo Nix builds should
  win, which means prefix.
- **Build hermes with `propagatedBuildInputs` carrying the subagent
  derivations**: rejected because that would put `claude-code`, `codex`,
  etc. into hermes's Python `propagatedBuildInputs`, which is for Python
  packages, not binaries. wrapProgram is the idiomatic primitive for
  binary-discovery wiring.

**3. Hand-pinned `fetchurl` (not nvfetcher) for the source tarball.**

`cocoindex-code.nix` is hand-pinned with `fetchurl` + literal `sha256`.
Mirroring that pattern keeps the two slim overlays homogeneous and avoids
introducing a `nvfetcher.toml` entry for a single sdist URL that PyPI
serves at a deterministic path. Bump procedure documented inline (curl
PyPI JSON, copy URL + sha256).

*Alternatives considered:*

- **`fetchPypi` with version + hash**: rejected because PyPI's pythonhosted
  paths embed a per-file hash prefix that `fetchPypi` resolves dynamically.
  This adds an evaluation-time round-trip and is no easier to bump than a
  literal URL. The cocoindex precedent uses `fetchurl`.
- **`src.pypi` via nvfetcher**: rejected because the autoupdate machinery
  isn't worth the ceremony for a single Python package. If hermes evolves
  to multi-platform wheels later, revisit.

**4. Add `**/.hermes/` to global gitignore.**

Symmetric with the existing `**/.cocoindex_code/` entry at
`modules/home/programs/git/default.nix:86`. Defensive: if a user ever runs
`hermes setup` from inside a repo checkout, `~/.hermes/` won't be at risk
of being staged, but any tool that creates a `.hermes/` cache subdirectory
near the repo would be caught. Cheap to add; matches the existing pattern
for AI assistants.

*Alternatives considered:*

- **Skip the gitignore entry**: rejected because the global gitignore
  already lists every AI assistant's dotdir (`.claude/`, `.codex/`,
  `.gemini/`, `.cursor/`, `.crush/`, `.goose/`, `.opencode/`,
  `.cocoindex_code/`). Omitting hermes breaks the pattern.

## Rollout & Gating

Four slices, gated by the standard dotfiles sequence: edit →
`nix flake check` → `nh os build` → user spot-check → `nh os switch`. Each
slice is independently revertible via `git revert`.

**Slice 1 — Overlay + packages.nix entry.** Land the new overlay and
register it. After this slice, `which hermes` resolves to a Nix store
path on demiurge.

- Gate: `nix flake check` passes; `nh os build` succeeds; user
  inspects the rendered closure for `hermes-agent-0.14.0`.
- Kill switch: `git revert` of the three files (overlay, overlays/default.nix,
  packages.nix) cleanly removes the package.

**Slice 2 — wrapProgram PATH verification.** No code changes; behavioral
verification only. User runs `hermes` from a fresh shell and confirms the
bundled `autonomous-ai-agents` skill for `claude-code` successfully spawns
its subagent.

- Gate: user manual confirmation. No automated assertion.

**Slice 3 — Runtime env-var matrix documented.** Capture which provider
needs which env var in design.md (already done — see Risks below for the
matrix), and surface a one-time `hermes setup` instruction in the user's
own notes (not in this repo's docs). User runs `hermes setup` on demiurge
and authenticates one provider end-to-end.

- Gate: `hermes` successfully completes a model-response round-trip with
  at least one provider (Anthropic OAuth is the default expected path).

**Slice 4 — Global gitignore entry.** Add `**/.hermes/` to the AI
assistants block at `modules/home/programs/git/default.nix:84-99`.

- Gate: `cat ~/.config/git/ignore | grep hermes` returns the new pattern
  after `nh os switch`.

**Wrap-up — Archive.** Only after slices 1–4 are all confirmed on
demiurge, archive `add-hermes-agent` via the openspec-archive skill.
Multi-host rollout (lv426 if applicable) follows the user's normal
sequence and does not block archive.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Hermes pyproject pins exact versions (`openai==2.24.0`, `httpx==0.28.1`, `pydantic==2.12.5`, etc.) but `nixpkgs-unstable` carries newer versions. `buildPythonApplication`'s dep resolution may fail on the version constraints. | Use `pyproject = true` with `pythonRelaxDeps` or `pythonRemoveDeps` if the build fails on a pin. Document the override list in the overlay. Accept that we run slightly newer versions than upstream tests — single-user dotfiles, not a production deployment, so the supply-chain pin discipline upstream relies on for fleet hardening doesn't apply here. |
| `wrapProgram`-wrapped PATH is correct at build time but a new bundled skill in a future hermes release may need a binary not in the wrapper list. | Capability spec scenarios enumerate the expected binaries. When a new hermes version is pinned, re-read its bundled-skills documentation; if a new subagent appears, add it to the wrapper. Surfaces as a runtime "command not found" — visible, debuggable. |
| `copilot login` is a runtime prerequisite for the `copilot-acp` provider; the overlay cannot enforce it. | Capability spec scenario explicitly states the assumption. User runs `copilot login` once per machine, before invoking the Copilot ACP path. Maps to a human-verification step in tasks.md. |
| `~/.hermes/auth.json` contains OAuth credentials. If the user runs `hermes setup` from inside a repo checkout and the directory ends up tracked, credentials leak. | Slice 4 adds `**/.hermes/` to the global gitignore. Defense in depth — the realistic case is `hermes setup` runs from `$HOME`, not a repo, but the ignore costs nothing and matches the existing AI-assistant ignore block. |
| The pinned `[anthropic]` extra (`anthropic==0.86.0`) is a very old SDK; if the user later wants the SDK-based code path (currently unexercised), they get stale tooling. | Out of scope for this change. If upstream makes the SDK extra mandatory for a provider the user uses, file a follow-up change to opt into the extra and accept the old SDK pin, or upstream a relaxation. |
| First `nh os switch` after this change adds hermes to the user's profile; on slow networks the PyPI fetch is non-trivial (~5–10 MB sdist + transitive Python deps that may need to build). | Standard build behavior; not unique to hermes. The user runs `nh os build` first (no profile change) to confirm the closure resolves before `nh os switch`. Maps to a human-verification step in tasks.md. |
| Hermes's interactive `hermes setup` prompts cannot be automated declaratively. User-driven, one-time-per-machine. | Acknowledged. Slice 3 of the rollout is explicitly the user running `hermes setup` manually and confirming. Same shape as `ccc init` for cocoindex. |

## Migration Plan

There's no existing hermes deployment to migrate from — this is greenfield
addition. The "migration" is just the first-time enablement on demiurge.

**Step 1 — verify clean baseline.** Before any edits:

- Confirm `nh os build` succeeds on the current main.
- Confirm `openspec validate add-hermes-agent` reports proposal/design/
  specs/tasks as the only artifacts and validation passes.

**Step 2 — apply Slice 1 (overlay + packages.nix).** Edit, then:

- `nix flake check`.
- `nh os build` (no system change yet).
- User reviews `git diff` of the three touched files.
- `nh os switch` on demiurge.
- Verify: `which hermes` returns a `/nix/store/...` path;
  `hermes --version` returns `0.14.0`.

**Step 3 — apply Slice 2 (wrapProgram PATH verification).** No edits;
verification only:

- From a fresh `bash -l`, run `hermes --help` and confirm the binary
  starts.
- Invoke the `autonomous-ai-agents-claude-code` bundled skill (per upstream
  docs at
  https://hermes-agent.nousresearch.com/docs/user-guide/skills/bundled/autonomous-ai-agents/autonomous-ai-agents-claude-code)
  and confirm hermes successfully spawns `claude-code`.

**Step 4 — apply Slice 3 (runtime env-var setup).** No edits; user action:

- User runs `hermes setup` on demiurge (interactive).
- User configures one provider end-to-end (default expectation:
  Anthropic OAuth via `hermes model` → "Anthropic").
- User confirms a successful model round-trip (any prompt → response).
- User confirms before the next slice.

**Step 5 — apply Slice 4 (gitignore entry).** Edit, then:

- `nix flake check`.
- `nh os switch` on demiurge.
- `cat ~/.config/git/ignore | grep '.hermes'` confirms the new pattern.

**Step 6 — archive.** Only after all prior slices are confirmed on
demiurge. Run `openspec archive add-hermes-agent` (requires explicit user
authorization per repo policy).

**Rollback:** any individual slice can be reverted with `git revert
<commit>` followed by `nh os switch`. Removing the overlay entirely is
clean — hermes is not load-bearing for any other tool in the repo.

## Open Questions

- **Should we eventually wrap a Linux-only path for `copilot` ACP**? The
  `copilot --acp --stdio` invocation is the same on darwin and linux; no
  per-platform divergence expected. Defer until evidence of breakage.
- **Should the overlay expose `hermes-agent` as a Python library**? Right
  now `buildPythonApplication` produces a wrapped binary. If the user
  later wants to script against the hermes Python API, switch to
  `buildPythonPackage` + a wrapped binary in `passthru`. Not a goal now.
- **Pinning strategy when Nous bumps the version**? Manual bump via PyPI
  JSON lookup, mirror of the cocoindex-code procedure. Document inline in
  the overlay header comment.
