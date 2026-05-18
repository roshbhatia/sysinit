## Why

Hermes is a Nous Research agent CLI that orchestrates other coding agents
(claude-code, codex, opencode) as autonomous sub-agents via bundled "skills,"
with first-class provider support for Anthropic, Google Gemini, GitHub
Copilot, and dozens of others. Adding it as a peer harness — managed
declaratively via Nix like every other tool in this repo — gives the user a
multi-agent shell that complements Claude Code without forcing per-host
imperative installs.

## What Changes

- New overlay at `overlays/hermes-agent.nix` packaging `hermes-agent` 0.14.0
  from PyPI as a slim `buildPythonApplication`. Follows the slim-overlay
  pattern just established by `overlays/cocoindex-code.nix` (zero optional
  extras; user enables providers at runtime).
- `wrapProgram` the `hermes` binary so its `PATH` is prepended with
  `claude-code`, `codex` (via `codex-acp`), `opencode`, `github-copilot-cli`
  (provides `copilot`), `gh`, and `gemini`. This is a build-time guarantee
  that bundled autonomous-AI-agent skills and Copilot ACP find their
  subagent binaries even if the user later trims `modules/home/packages.nix`.
- Register the new overlay in `overlays/default.nix` adjacent to
  `cocoindex-code.nix`.
- Add `hermes-agent` to the "AI & Editors" cluster in
  `modules/home/packages.nix`.
- Add `**/.hermes/` to the global gitignore at
  `modules/home/programs/git/default.nix` (symmetric with the existing
  `**/.cocoindex_code/` entry; protects accidentally-committed OAuth tokens
  in `~/.hermes/auth.json` if a user ever runs `hermes setup` inside a repo
  checkout).

### Non-goals

- **No declarative `~/.hermes/` config.** `config.yaml`, `auth.json`, `.env`,
  and `auth/*` are per-machine, user-mutable state. Managing them in Nix
  would clobber `hermes config set` / `hermes model` runtime mutations on
  every `nh os switch`. Matches the `ccc init` precedent for cocoindex.
- **No Python extras.** `hermes-agent` ships `anthropic`, `exa`, `firecrawl`,
  `fal`, `edge-tts`, `modal`, `daytona`, `parallel-web`, and `aws` (boto3)
  as optional extras. Every provider the user cares about works *without*
  extras per the upstream provider matrix
  (https://hermes-agent.nousresearch.com/docs/integrations/providers).
- **No messaging integrations.** No Node.js v22, no Playwright/Chromium, no
  WhatsApp/Telegram/Discord/Slack bridges. Out of scope; the user can add
  per-host if they want them.
- **No MCP coupling.** Hermes is a peer to Claude Code, not a child. No
  cocoindex/ast-grep/playwright wired into hermes; no hermes-as-MCP-server
  for the Claude Code harness.
- **No API-key plumbing in Nix.** `ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`,
  `COPILOT_GITHUB_TOKEN`, `OPENROUTER_API_KEY`, etc. live in the user's
  shell or `~/.hermes/.env`. 1Password integration, if used, is a
  shell-level concern shared with every other API-keyed tool.

## Capabilities

### New Capabilities

- `hermes-agent-cli`: declares that the `hermes` CLI is built from upstream
  PyPI source via a Nix overlay; that its `PATH` carries the in-repo
  subagent binaries it spawns; that `~/.hermes/` is unmanaged user state;
  and that provider authentication is the user's runtime responsibility.

### Modified Capabilities

None. The change adds a new capability without altering existing ones.

## Impact

- **Code**:
  - NEW `overlays/hermes-agent.nix`
  - `overlays/default.nix` (additive import)
  - `modules/home/packages.nix` (one-line addition to AI & Editors cluster)
  - `modules/home/programs/git/default.nix` (one-line addition to AI
    assistants ignore block)
- **Dependencies**: PyPI source tarball for `hermes-agent==0.14.0`
  (hand-pinned with `fetchurl` + sha256; same pattern as `cocoindex-code`).
  Transitive Python dependencies resolved against `nixpkgs-unstable`'s
  `python3Packages`. The pyproject pins core deps to exact versions; if the
  current nixpkgs revision carries newer versions of `openai`, `httpx`,
  `pydantic`, `pyyaml`, `tenacity`, etc., the overlay accepts that
  divergence rather than vendoring older pins (rationale captured in
  design.md).
- **Pattern reuse**: This change deliberately mirrors
  `overlays/cocoindex-code.nix` for the overlay shape and the
  unmanaged-runtime-config decision. No new infrastructure introduced.
- **Impactful actions requiring human verification**:
  - `nh os switch` on demiurge after the overlay lands — first time hermes
    appears in the user's profile. The user must run `hermes setup`
    manually afterwards (interactive; can't be automated by the spec).
  - First-time provider authentication (`hermes model` for OAuth flows;
    setting env vars for API-key providers). User verifies one
    provider reaches a successful response before declaring the change
    archive-ready.
- **Gating signal**: standard `nh os build` (validate closure) →
  `nh os switch` (apply) flow. The overlay can be reverted with a single
  `git revert` if the build closure fails or the wrapper breaks any
  subagent invocation.
- **Progressive rollout**: four slices in `tasks.md`. Overlay + packages
  entry first (smoke-test `which hermes`); wrapProgram PATH verification
  second; runtime env-var matrix documentation third; gitignore entry
  fourth. Each slice is independently revertible.
