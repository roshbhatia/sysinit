## Context

This change re-introduces a system-information fetch tool that was removed
when `modules/home/configurations/macchina/` was deleted in commit
`aef318858` ("yamlhatred"). Three precedents in the current repo shape the
shape of the new module:

- **Stylix-via-`config.lib.stylix.colors`** is the established palette
  consumer. `modules/home/programs/fzf.nix:50-90` and
  `modules/home/programs/helix.nix` both interpolate `base05`, `base0D`,
  etc. into upstream config formats. Any new module that wants colors uses
  this attribute path, not a hand-coded palette or a sibling lookup.
- **`programs.<tool>` enable + `settings` attrset** is how every modern
  home-manager-managed tool ships here (`programs.fzf`, `programs.bat`,
  `programs.eza`, `programs.helix`, `programs.git`). `programs.fastfetch`
  upstream takes `enable` + `settings`; `settings` is rendered to JSON at
  build time. This is exactly the shape we want — no raw JSONC, no
  `xdg.configFile."fastfetch/config.jsonc"`.
- **Hostname-conditional behavior** is read off
  `osConfig.networking.hostName` on darwin and `config.networking.hostName`
  on nixos. `modules/home/programs/ssh.nix` and the lima-gating in
  `modules/home/programs/llm/` already use this exact pattern.

The upstream model is
[dededecline/dotfiles/fastfetch/config.jsonc](https://github.com/dededecline/dotfiles/blob/main/fastfetch/config.jsonc).
We are *not* copying its file structure — we are translating its module
list into a Nix expression that produces the same rendered JSON, with the
color literals replaced by stylix lookups.

The six historical macchina ASCII arts (`rosh.ascii`, `rosh-color.ascii`,
`nix.ascii`, `mgs.ascii`, `vagabond.ascii`, `varre.ascii`) were recovered
from `aef318858^:modules/home/configurations/macchina/themes/`. The
`rosh-color.ascii` file contains ANSI escape sequences embedded in the
art itself and renders independently of the configured `logo.color`; the
other five are monochrome and recolor via `logo.color.1`. They will be
renamed from `.ascii` to `.txt` to match dede's convention and to make
the file purpose obvious from extension.

`laurel.txt` is byte-identical to
[`logo_hera.txt`](https://github.com/dededecline/dotfiles/blob/main/fastfetch/logo_hera.txt)
with a one-line `# attribution: dededecline/dotfiles logo_hera` comment
prepended (fastfetch ignores leading lines starting with `#` in
`type = "file"` mode — verified against the upstream JSON-schema).

## Goals / Non-Goals

**Goals:**

- One home-manager module, identical across all hosts in module body, that
  enables `fastfetch` with a Nix-derived `settings` attrset matching dede's
  layout (Hardware → Firmware → Software → Theme → Network → colors).
- Stylix-driven cluster colors so theme changes propagate without editing
  the module. Specifically:
  - Title key (was Rosewater `242;213;207`) → `base05` (foreground)
  - Hardware cluster (was Flamingo `238;190;190`) → `base08` (red/love)
  - Firmware cluster (was Maroon `234;153;156`) → `base09`
    (integers/constants — dusty orange family)
  - Software cluster (was Red `231;130;132`) → `base0F`
    (deprecated/embedded — dusty rose)
  - Theme cluster (was Mauve `202;158;230`) → `base0E` (keywords / iris)
  - Network cluster (was Blue `140;170;238`) → `base0D` (functions / blue)
  - Separator (was Lavender `148;156;187`) → `base03` (comments / muted)
  - Logo color 1 (was Lavender `186;187;241`) → `base0D` (matches network)
- Hostname → default-art selection happens at evaluation time. Resulting
  closure contains a single `fastfetch/logo.txt` symlink per host pointing
  at the correct art.
- Both darwin and nixos hosts build green and render correctly.
- All seven art files (`rosh`, `rosh-color`, `nix`, `mgs`, `vagabond`,
  `varre`, `laurel`) live in `${xdg.configHome}/fastfetch/art/` so the
  user can re-point `logo.txt` at any of them manually without rebuilding.

**Non-Goals:**

- See proposal Non-goals — no macchina revival, no shell auto-run, no per-host
  divergence in the module body.
- No attempt to derive *all* fastfetch colors from base16 — only the cluster
  key/separator colors. Module-internal formatting strings (`{?is-primary}
  *{?}`, etc.) stay as-is.
- No support for a `fastfetch.art` Nix option that picks art by name. The
  hostname map is the only selector. If the user wants per-host overrides
  beyond `lv426 / demiurge / arrakis / nostromo`, they edit the map.

## Decisions

**1. Translate dede's JSONC into a Nix `settings` attrset, not vendored
   verbatim.**

The home-manager `programs.fastfetch.settings` option is rendered with
`pkgs.formats.json`. Translating the JSONC to Nix gives us:

- Interpolated stylix colors (`"38;2;${...base08.r-int};${...base08.g-int};${...base08.b-int}"`),
- Per-platform module list (`Software` cluster differs by `pkgs.stdenv.isDarwin`),
- One source of truth on disk instead of two files to keep in sync.

*Alternatives considered:*

- **Vendor `config.jsonc` verbatim and source it via `xdg.configFile`**
  (the macchina pattern). Rejected: bypasses the home-manager module
  entirely (the proposal explicitly requires using it), no stylix wiring,
  no per-platform module list without sed-substitution at build time.
- **Use `xdg.configFile` to write a Nix-templated JSONC.** Rejected:
  re-implements what `programs.fastfetch.settings` already does and breaks
  if upstream adds settings-validation in a future home-manager release.

**2. Convert hex stylix colors to `"38;2;R;G;B"` SGR sequences in Nix.**

Fastfetch wants raw SGR parameters in `keyColor` / `color.separator` /
`color.1`. The repo has `config.lib.stylix.colors.base05` (hex string) and
`base05-rgb-r` / `base05-rgb-g` / `base05-rgb-b` (decimal channel values,
provided by stylix's color library). The module uses the `-rgb-*` accessors:

```nix
sgr = base: "38;2;${toString config.lib.stylix.colors."${base}-rgb-r"};${toString config.lib.stylix.colors."${base}-rgb-g"};${toString config.lib.stylix.colors."${base}-rgb-b"}";
```

*Alternatives considered:*

- **Pre-convert hex to RGB in pure Nix.** Rejected: stylix already provides
  decimal channel attributes; reimplementing hex parsing in Nix is
  unnecessary infrastructure (proposal rule 1).
- **Use `${config.lib.stylix.colors.base08}` directly as a `"#RRGGBB"`
  hex literal in the fastfetch settings.** Rejected: fastfetch parses
  `keyColor` as ANSI SGR parameters, not a CSS color. Hex strings render
  as literal text in the output.

**3. Hostname dispatch by reading `osConfig.networking.hostName`.**

`programs.fastfetch.nix` runs in home-manager scope. On darwin, the
ambient `osConfig` argument exposes the nix-darwin-side `networking`
namespace; on nixos, `config.networking.hostName` is in scope. Both
collapse to:

```nix
hostName =
  osConfig.networking.hostName
    or config.networking.hostName
    or "unknown";
artName = {
  lv426 = "rosh";
  demiurge = "laurel";
  arrakis = "nix";
  nostromo = "nix";
}.${hostName} or "rosh";
```

The `or` chain handles the case where neither namespace is set (e.g.
home-manager-standalone), defaulting to `rosh`.

*Alternatives considered:*

- **Read a per-host `values.fetchArt` attribute set in
  `hosts/default.nix`.** Rejected: every host would need a new field for
  a four-line lookup table. The proposal's Non-goals already declare
  per-host configurability beyond the four-entry map out of scope.
- **Use `pkgs.system` instead of hostname.** Rejected: `lv426` and
  `demiurge` are both `aarch64-darwin`; system alone cannot disambiguate.

**4. Ship art files as a sibling directory, not inline strings.**

The art files contain ANSI escape sequences (`rosh-color.txt`),
embedded special characters, and are conceptually static binary blobs.
Pulling them in via `./fastfetch/art/rosh-color.txt` (literal path) keeps
them readable in `git diff`, lets us byte-copy them out of `git show
aef318858^:...`, and avoids string-quoting hazards.

*Alternatives considered:*

- **Inline as `''…''` multi-line strings.** Rejected: `rosh-color.txt`
  contains backslashes, `''` sequences, and bytes outside the Nix string
  comfort zone; round-trip through Nix-string-escaping is risky.
- **Fetch from upstream URLs at build time.** Rejected: introduces a
  network dependency, dede's repo could move, and macchina art was
  authored locally — no upstream URL exists for five of the seven files.

**5. Platform-conditional `Software` cluster module list.**

Dede's `Packages` module shells out to `/opt/homebrew/Cellar`, `Caskroom`,
and `mas`. On NixOS these paths don't exist; the equivalent count is
`nix-store -q --requisites /run/current-system | wc -l`. The module list
is built in Nix:

```nix
softwareModules = lib.optionals pkgs.stdenv.isDarwin [
  { type = "command"; key = "├ Packages"; text = "<brew/cask/mas>"; ... }
] ++ lib.optionals pkgs.stdenv.isLinux [
  { type = "command"; key = "├ Packages"; text = "nix-store -q --requisites /run/current-system | wc -l | tr -d ' '"; ... }
];
```

The Theme cluster's `defaults read -g AppleInterfaceStyle` call is also
darwin-only; on NixOS it's omitted (no system-wide dark/light toggle in
this user's NixOS configuration).

*Alternatives considered:*

- **One module list with shell commands that detect platform at runtime.**
  Rejected: fragile (the shell command runs in fastfetch's environment,
  not the user's), harder to read.
- **Skip the Software cluster on NixOS entirely.** Rejected: package
  count is the most useful single line of the cluster; we have a clean
  substitute.

## Rollout & Gating

Standard dotfiles gating: edit → `nix flake check` (validates flake-wide
type-checking) → `nh os build` (builds host closure without applying) →
inspect rendered `fastfetch/logo.txt` symlink and `config.jsonc` in
`/nix/store/.../home-files/.config/fastfetch/` → `nh os switch` → user
runs `fastfetch` on each active host and confirms art + cluster colors
render as expected.

Gate sequence per slice (see tasks.md):

1. **Slice 1 — module + art files** gates on `nix flake check` and `nh os
   build` for the local darwin host. No `nh os switch` yet; this slice
   only adds files and one import line. Failure mode: type error in the
   `settings` attrset surfaces in `nh os build`. Rollback: `git revert`.
2. **Slice 2 — hostname dispatch + stylix wiring** gates on `nh os build`
   producing a `config.jsonc` whose `keyColor` fields contain the
   expected SGR strings (verify by reading the store path). Then `nh os
   switch` on the local host. Failure mode: hostname returns `null` or
   stylix attribute path is wrong → build error. Rollback: `git revert`,
   re-run `nh os switch` to drop fastfetch.
3. **Slice 3 — per-host verification** is human-only: visit each active
   host, run `fastfetch`, confirm correct art and colors. No automated
   gate; the user's eyes are the gate.

No feature flag is needed — `fastfetch` is a new binary on $PATH and a
new config file; reverting is mechanical. The natural kill switch is the
single import line in `modules/home/programs/default.nix`; commenting it
out drops the entire module from the closure.

## Risks / Trade-offs

- **[Stylix attribute path drift]** → if a future stylix release renames
  `base05-rgb-r` to something else, the module fails to evaluate.
  Mitigation: pin the SGR-construction helper to one place in the module
  (single `sgr` let-binding); if the path changes, one edit fixes every
  cluster. Maps to a human-verification checkpoint after any `nix flake
  update stylix` touching the lockfile.
- **[Hostname collision with future hosts]** → adding a new host that
  isn't in the four-entry map silently falls back to `rosh`. Mitigation:
  call out the map's location in the spec so future host additions
  remember to add an entry. Acceptable — the fallback is fine, just
  generic.
- **[Art ANSI sequences interact badly with stylix logo.color.1]** →
  `rosh-color.txt` carries its own embedded colors; setting `color.1`
  has no effect on those bytes (correct behavior), but the title block
  on the same row inherits `color.1`. Trade-off: accept the visual
  mismatch on `rosh-color`; document that it's intended.
- **[macOS-only `defaults read` in Theme cluster fails silently on
  Linux]** → covered by the platform-conditional module list (Decision
  5). Risk only materializes if the conditional is wrong.
- **[Brew/cask/mas count is slow on a fresh shell]** → dede's command
  runs three `ls | wc -l` invocations. On a cold filesystem, this can
  add ~200ms to fastfetch startup. Trade-off: accepted; fastfetch is
  interactive, not a hot path. Future optimization could cache the
  count.

## Migration Plan

1. **Verify pre-state.** Confirm no existing `programs.fastfetch` or
   `xdg.configFile."fastfetch/..."` is set in the repo (`rg -i fastfetch
   modules/`). Confirm `aef318858^` is reachable (`git rev-parse
   aef318858^`). Both must succeed before proceeding.
2. **Slice 1 — module + art files (local-only, no rebuild).** Land
   `modules/home/programs/fastfetch.nix`, the seven art files, and the
   import line. Run `nix flake check` and `nh os build`. Confirm closure
   builds and the rendered store path contains the expected files. **No
   `nh os switch` yet.** If `nh os build` fails, `git reset HEAD~`,
   investigate.
3. **Slice 2 — hostname dispatch + stylix wiring (local rebuild).**
   `nh os switch` on the host being developed against (`lv426` or
   wherever the user is). Run `fastfetch`. Verify (a) the correct art
   shows, (b) cluster colors look right, (c) no error from the
   `defaults read` or brew commands. Confirm before continuing.
4. **Slice 3 — verify the other active hosts.** SSH into `demiurge` and
   `arrakis` (separately), pull the change, `nh os switch`, run
   `fastfetch`, confirm. `nostromo` is the lima VM; if the user runs it,
   verify there too. Each host is an independent verification
   checkpoint; if any one fails, fix before declaring the change
   archive-ready.

Rollback at any point: `git revert <commit>` of the slice that broke,
then `nh os switch` to drop the change. No external state to clean up
(no daemon registered, no `~/.local/share/...` files written).

## Open Questions

- Should the brew/cask/mas package-count command be moved into a small
  shell helper in `hack/` so it's testable independently? Lean toward
  no — it's a one-shot, and inlining matches dede's pattern.
- Does the user want a CI smoke test that renders `fastfetch --no-color
  --pipe` and compares against a golden file? Out of scope for this
  change but a natural follow-up.
