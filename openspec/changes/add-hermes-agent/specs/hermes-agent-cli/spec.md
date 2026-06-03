## ADDED Requirements

### Requirement: hermes binary is installed declaratively
The `hermes` CLI from upstream `hermes-agent==0.14.0` SHALL be available on the user's `PATH` after `nh os switch`, sourced from a Nix overlay rather than imperatively installed (pipx, brew, curl|bash, etc.). The package SHALL appear in `home.packages` via `modules/home/packages.nix`.

#### Scenario: Binary resolves after activation
- **WHEN** `nh os switch` completes on a host where the overlay is registered
- **THEN** `which hermes` returns a `/nix/store/...-hermes-agent-0.14.0/bin/hermes` path
- **AND** `hermes --version` reports `0.14.0`

#### Scenario: Build fails when overlay source is unreachable
- **WHEN** `nh os build` runs while the upstream PyPI source tarball cannot be fetched (network failure, checksum mismatch, sdist deleted from PyPI)
- **THEN** the build fails with a clear `fetchurl` error citing the offending URL and expected hash
- **AND** no partial install is written to the user's profile

### Requirement: Subagent binaries are reachable via wrapped PATH
The `hermes` binary SHALL be wrapped (via `wrapProgram` or equivalent) so that `claude-code`, `codex` (provided by `codex-acp`), `opencode`, `copilot` (provided by `github-copilot-cli`), `gh`, and `gemini` are prepended to its `PATH`. This guarantee SHALL hold when `hermes` is invoked from any shell, including minimal subprocess environments where the parent `PATH` does not include those derivations.

#### Scenario: Bundled autonomous-AI-agent skill finds claude-code
- **WHEN** a hermes session invokes the `autonomous-ai-agents-claude-code` bundled skill from a fresh `bash -l` shell
- **THEN** hermes successfully spawns the `claude-code` binary
- **AND** the spawn does not rely on the user's interactive shell having `claude-code` on `PATH`

#### Scenario: Copilot ACP provider finds copilot binary
- **WHEN** the `copilot-acp` provider is selected and hermes spawns `copilot --acp --stdio`
- **THEN** the wrapped `PATH` resolves `copilot` to the `github-copilot-cli` derivation
- **AND** the subprocess starts (subject to the user having run `copilot login` once on the machine — see runtime-prerequisite scenario below)

#### Scenario: Wrapper does not override an explicit user PATH entry
- **WHEN** the user runs `PATH=/custom/bin:$PATH hermes` with `/custom/bin/claude-code` present
- **THEN** the wrapper's prepend SHALL place the Nix-managed `claude-code` ahead of `/custom/bin/claude-code`
- **AND** hermes uses the Nix-managed binary (this is the intentional default; users wanting otherwise can edit the overlay)

#### Scenario: Missing subagent at build time fails the closure
- **WHEN** the overlay references a subagent derivation that no longer exists in the active overlay set (e.g. `gemini` is removed from `overlays/default.nix`)
- **THEN** `nh os build` fails with a `cannot find attribute` error citing the missing derivation
- **AND** the failure surfaces before any new closure is activated

### Requirement: Runtime configuration is user-owned
The overlay SHALL NOT write to `~/.hermes/`, `/etc/`, or any other path outside the Nix store during build or activation. `~/.hermes/config.yaml`, `~/.hermes/auth.json`, `~/.hermes/.env`, and `~/.hermes/auth/*` SHALL be mutable user state owned by the user, mutated only via `hermes setup`, `hermes model`, `hermes config set`, or direct user edits.

#### Scenario: Activation does not touch user config
- **WHEN** `nh os switch` runs on a machine where `~/.hermes/config.yaml` has been edited by the user
- **THEN** the file is unchanged after activation
- **AND** `hermes` invocations use the user's edited config without warning or override

#### Scenario: Fresh install leaves config absent until user opts in
- **WHEN** `nh os switch` runs on a machine where `~/.hermes/` does not exist
- **THEN** `~/.hermes/` is NOT created by activation
- **AND** the user must run `hermes setup` interactively to initialize the directory

#### Scenario: Activation refuses to clobber pre-existing state
- **WHEN** a future change inadvertently attempts to write a declarative `~/.hermes/config.yaml` via `home.file` or activation
- **THEN** the build SHALL fail at `nh os build` time with a collision error on the existing user-owned path
- **AND** the user can revert without losing their hand-edited config

### Requirement: API key plumbing is out of band
The overlay SHALL NOT bake any provider API key, OAuth credential, or auth token into the Nix store. Provider authentication SHALL be performed at runtime via environment variables (`ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`, `COPILOT_GITHUB_TOKEN`, `OPENROUTER_API_KEY`, `XAI_API_KEY`, etc.), via interactive OAuth flows initiated by `hermes model`, or via `gh auth token` fallback for GitHub-derived tokens.

#### Scenario: No secrets in the closure
- **WHEN** the rendered `hermes-agent-0.14.0` derivation is inspected (e.g. `nix-store --query --references`)
- **THEN** no file under `/nix/store/...-hermes-agent-*/` contains an API key, OAuth refresh token, or credential payload
- **AND** the derivation's substitutability is preserved (any user with the same nixpkgs revision builds the same store path)

#### Scenario: Missing credentials surface as runtime errors
- **WHEN** the user invokes a provider (e.g. `hermes model` → "Anthropic") without setting `ANTHROPIC_API_KEY` and without completing OAuth
- **THEN** hermes itself reports the missing credential at runtime
- **AND** the overlay does NOT pre-flight or short-circuit the failure during build or activation

### Requirement: No MCP coupling
The overlay SHALL NOT register hermes as an MCP server in `modules/home/programs/llm/config/mcp-servers.nix`, and SHALL NOT add MCP servers from this repo (ast-grep, playwright) into hermes's own tool registry. Hermes SHALL operate as a peer agent harness, not a child of Claude Code or any other tool that consumes the repo's MCP server registry.

#### Scenario: MCP server registry is untouched
- **WHEN** the rendered `mcp-servers.nix` config is generated post-activation
- **THEN** no `hermes` entry appears in `sysinit.llm.mcp.additionalServers`
- **AND** Claude Code, codex, and other harnesses see no `hermes` tool in their tool inventories

#### Scenario: Hermes's own tool registry is unmodified by the overlay
- **WHEN** the user inspects hermes's tool list via `hermes tools` after activation
- **THEN** only the bundled hermes tools and any user-configured external tools are present
- **AND** no `ast-grep:*` or `playwright:*` entries are injected by the overlay

### Requirement: Runtime prerequisites are explicit
The capability SHALL document, at the spec level, which runtime actions the user must perform that the overlay cannot enforce. These include: (a) running `hermes setup` once per machine to initialize `~/.hermes/`; (b) running `copilot login` once per machine before using the `copilot-acp` provider; (c) setting provider API key env vars in the user's shell or `~/.hermes/.env`; (d) completing interactive OAuth flows via `hermes model` for OAuth-based providers (Anthropic OAuth, Gemini OAuth, MiniMax OAuth, etc.).

#### Scenario: First-time hermes setup is user-driven
- **WHEN** a user with a fresh activation runs `hermes` for the first time without having run `hermes setup`
- **THEN** hermes prompts the user to run `hermes setup` (or its equivalent setup flow)
- **AND** the overlay/activation does NOT auto-run setup

#### Scenario: copilot-acp without copilot login fails gracefully
- **WHEN** the user selects `copilot-acp` as the provider before running `copilot login` on the machine
- **THEN** hermes (or the spawned `copilot --acp --stdio` subprocess) reports the missing auth state at runtime
- **AND** the failure mode is a clear error message, not a silent hang
