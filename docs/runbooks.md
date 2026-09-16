# Runbooks

Recipes for the changes this repository takes often. Each one names the files
to edit and the gate that proves the change.

`AGENTS.md` holds the command list, the gate inventory, and the known
footguns. This file does not repeat them.

## Add a package that nixpkgs already carries

Pick the tier by who needs the tool.

| Tier | File | Reaches |
| --- | --- | --- |
| `minimal` | `modules/home/tools.toml` | every profile, including a bare box |
| `dev` and above | `modules/home/packages.nix` | workstation profiles |
| One host only | that host's entry in `hosts/default.nix` | that host |

`tools.toml` entries carry the nixpkgs attribute name and nothing else:

```toml
[[tool]]
nix = "ripgrep"
```

Then run `nix flake check`.

## Add a package that nixpkgs does not carry

Write an overlay under `overlays/`, then register it in the list in
`overlays/default.nix`. Choose the source mechanism first.

- The upstream tags releases and you want them tracked: add a block to
  `nvfetcher.toml`, run the nvfetcher command in the header of that file, and
  read the pinned source from `_sources/generated.nix`.
- The upstream is a flake: add it as a flake input and import it through
  `overlays/inputs.nix`.
- The version moves rarely: pin the revision and hash in the overlay itself.

Name the attribute `sysinit-<tool>` when nixpkgs also defines that name. An
unprefixed attribute silently shadows the nixpkgs package, and only the
`REMOVED` lines in `nh` output report it.

Gate a Darwin-only workaround on `stdenv.hostPlatform.isDarwin`. Overlays apply
to every host, so an ungated Darwin fix breaks the Linux build.

## Update a Go package after a `go.mod` change

`vendorHash` is not derived from the source. Run:

```bash
./hack/update-vendor-hash.sh
```

The script finds every overlay that declares a `vendorHash`, builds each one,
and writes back the hash Nix reports. It restores the original file if it is
interrupted.

A `pkgs/go.mod` edit breaks `overlays/sysinit-gotools.nix`. Search the whole
`nh` output for `error:`, not the tail; the failure is not always last.

## Bump pinned sources

- Flake inputs: `nix flake update`, or `nix flake update <input>` for one.
- nvfetcher sources: the command in the `nvfetcher.toml` header.
- The forked openspec schema: `./hack/sync-openspec-schema.sh` reports drift.

CI opens a pull request for the first two on a schedule. Run them by hand only
when you need the bump now.

## Put a package in the binary cache

Add the attribute name to `cacheAttrs` in `flake.nix`. Put Linux-only
attributes in `linuxCacheAttrs` instead.

The bundle resolves strictly. A name that no overlay defines fails the flake
check rather than shrinking the bundle, so a rename cannot quietly send the
build back to the laptop.

A package that no overlay attribute names cannot go in `cacheAttrs`. Add it to
`linuxInputPackages` in `flake.nix` instead, which reads the flake input
directly. `swayfx` is the one entry today.

CI builds the `lv426` closure but not the `arrakis` closure. Measured
2026-09-14, `arrakis` needs 1298 built derivations and 31.2 GiB unpacked. A
hosted runner has 14 GiB free and a 6 hour limit. Cache the expensive leaves
through `linuxCacheAttrs` and let `arrakis` link the closure itself.

Confirm a path is cached before you blame a slow switch:

```bash
nix path-info --store https://roshbhatia.cachix.org <store-path>
```

A test-skip override (`doCheck = false`, `disabledTests`,
`disabledTestPaths`) changes the derivation hash. The upstream cache then
misses, and the package builds from source. Keep such a package out of
`cacheAttrs`, or drop the override.

## Add a host

Add an entry to `hosts/default.nix`. A host declares `system`, `platform`,
`username`, and its own `values`. A NixOS host also names a `hardware` module
under `modules/nixos/hardware/`.

`flake.nix` splits the set by `platform` into `darwinConfigurations` and
`nixosConfigurations`. No other file needs the new name.

Evaluate before you switch:

```bash
nix eval .#darwinConfigurations.<name>.system --raw
```

## Add a module

| Scope | Directory |
| --- | --- |
| Both platforms | `modules/shared/` |
| macOS system | `modules/darwin/` |
| NixOS system | `modules/nixos/` |
| User environment | `modules/home/` |

Import it from the `default.nix` of that directory. Declare its settings as
options and read them through `config`, not through the raw `values` argument.
Cross-platform options live in `modules/shared/options/`; macOS-only options
live in `modules/darwin/options.nix`. An option that no module reads is not a
gate: a bad value reaches the generated file unchecked.

Keep a value that both platforms need in one file and import it from both.

## Run the gates

`.githooks/pre-commit` runs `hack/lint.sh` on the staged files, so most
violations become a rejected commit. Before a switch, run `nix fmt` and
`nix flake check`.

Some invariants are module assertions and fire only on `nix eval` of a host.
`nix flake check` does not reach all of them. Evaluate configurations in
platform batches to share package sets while bounding evaluator memory:

```bash
for system in aarch64-darwin x86_64-linux aarch64-linux; do
  nix eval --json ".#lib.configurationDerivations.$system"
done
```

## Build once and activate

Use the installed `nh`; development shells supply tools for checks. Keep the
built result rooted through review and activation:

```bash
nh darwin build . --out-link result-system
sudo nix-env -p /nix/var/nix/profiles/system --set "$(realpath result-system)"
sudo ./result-system/sw/bin/darwin-rebuild activate
```

On the work Mac, run these commands from `sysinit.laurel`. Update its pinned
`sysinit` input after the upstream commit is pushed. The output path deploys the
reviewed build even if the checkout changes afterwards.

## Configure a remote builder

Darwin activation creates `/var/root/.ssh/sysinit-builder` once. The private
key stays on its Mac. Enroll its public key in `modules/nixos/nix-builder.nix`
and switch Arrakis before using the builder. Each Mac needs its own key.
The forced SSH command exposes only the Nix daemon, with forwarding disabled.

The daemon pins Arrakis's host key through `programs.ssh.knownHosts`. When the
host key changes, verify it through an existing authenticated connection before
updating the declaration. Check the connection as root:

```bash
sudo nix store ping --store 'ssh-ng://nix-builder@arrakis.stork-eel.ts.net?ssh-key=/var/root/.ssh/sysinit-builder'
```

Arrakis builds x86_64 Linux outputs. Native Darwin outputs build on macOS.

## Populate caches

`build-cache.yml` builds package bundles and development tools after package
inputs change. `system-cache.yml` builds host closures after module, host, or
package changes. The cache action queries only the requested derivations' dependency graph,
including completed outputs. Successful dependencies upload even if a later
build fails, without a privileged hook or a scan of the shared store. Private work-machine
configurations stay out of the public cache.

## Recover a failed switch

A `nh darwin switch` that fails part way leaves the previous generation
active. Roll back with:

```bash
darwin-rebuild --list-generations
sudo darwin-rebuild --switch-generation <n>
```

On NixOS the equivalents are `nixos-rebuild --list-generations` and the boot
menu.

A switch that fails with store errors under a nearly full disk is usually the
Determinate garbage collector racing the unrooted switch window. Free space
first:

```bash
nh clean all
```

## Arrakis GitHub runner

`github-runner-sysinit.service` runs trusted `roshbhatia/sysinit` main jobs on
Arrakis. Labels are `self-hosted`, `Linux`, `X64`, `arrakis`, `nix`, and `tailscale`.
PR checks use GitHub-hosted runners. Keep approval required for all external
contributors; do not approve a PR that directs untrusted code to Arrakis.
The runner's pre-job hook also rejects PR events and refs other than main.

The NixOS module uses the host Nix daemon and existing Tailscale connection.
It does not grant the runner sudo or access to the interactive user's home.
The cache workflows push their output closures with the repository Cachix secret.
The x86_64 cache job also builds and publishes the Arrakis system closure.

Before first activation, mint a repository registration token and place it at
`/var/lib/secrets/github-runner-sysinit` on Arrakis, owned by root with mode 0600.
Keep it outside the Nix store. Registration tokens expire after one hour.
Existing runner credentials survive restarts; changes to runner registration
settings require a fresh token before restarting the service.

Check registration with `gh api repos/roshbhatia/sysinit/actions/runners`.
Check service logs with `journalctl -u github-runner-sysinit` on Arrakis.
Dispatch the `Arrakis runner` workflow to verify job execution, Tailscale,
and a Nix build through the daemon.

## Private Ere runners

Every profile installs `ere`, `limactl`, `kubectl`, `virtctl`, and SSH.
The work Mac inherits the same setup through `sysinit.laurel`.
`~/.config/ere/config.yaml` declares a local Lima runner. The separate
`arrakis.yaml` and `vorgossos.yaml` files declare StatefulSet and KubeVirt runners.
Runner names include the controller host to prevent collisions between Macs.

Prepare remote access through the existing SSH connection:

```bash
ere-setup arrakis
ere-setup vorgossos
ere api runner_profiles
ere --config ~/.config/ere/arrakis.yaml api runner_profiles
```

The setup command writes separate mode-0600 admin kubeconfigs. It preserves
the default context and creates a dedicated guest SSH key if none exists.
Credentials do not enter the Nix store. Arrakis's NixOS service installs pinned
KubeVirt and CDI releases. Homelab owns those services on Vorgossos.

Before starting a VM, import its declared boot volume:

```bash
kubectl --kubeconfig ~/.kube/ere-arrakis.yaml apply -f ~/.config/ere/arrakis-boot.yaml
kubectl --kubeconfig ~/.kube/ere-arrakis.yaml -n ere get datavolumes
```

Use the corresponding Vorgossos paths for that cluster. Boot and workspace
volumes use retained storage classes. StatefulSet runners install Amp during
startup and retain their workspace PVCs after compute removal. Lima guest disks
survive `down`; `rm` removes them.

Set `AMP_API_KEY` through your secret manager before `ere up <runner-name>`.
Use `--config` to select a remote cluster and select one runner by name.
Bare `up` starts every runner in the selected file. A successful `plan` verifies
the declared compute changes; an Amp task verifies actual runner registration.

## Format source and generated files

Run `nix fmt` to apply the formatters in `treefmt.toml`. Use
`nix fmt -- --check` for a check that leaves the working tree unchanged.
The check formats a temporary copy of tracked files. Stage new files first.
Hooks use the same configuration through `hack/format.sh` in the Nix shell.

Use the language formatter: nixfmt, shfmt, StyLua, gofmt, Ruff, nufmt,
fish_indent, Taplo, Prettier, clang-format, or cue fmt. Lockfiles, fetched
sources, and vendor directories stay under their upstream generators.
Zsh and jq programs retain their syntax checks; Bash formatting is not valid
for arbitrary Zsh syntax.

Generate local shell commands with `pkgs.sysinit.writeShellApplication`,
`writeShellScript`, or `writeShellScriptBin`. These builders format the fully
expanded script with shfmt before the existing checks. Generate JSON with
`pkgs.sysinit.writeJSON name value`, which uses the native Nix JSON generator.
Use `pkgs.formats` for other structured configuration formats.

## Compose local utilities

`y` and `f` use Yazi's native directory-changing shell wrapper. `fd` respects
repository ignore rules; use `fda` to search ignored files. `find` retains its
standard meaning. Fzf file selection supports multiple results with Ctrl-Space;
history and directory selection use their own modes.

Enable session planning explicitly with `sysinit.seshy.planning.enable`.
Append independent commands through `sysinit.seshy.postCreateHooks`.
`sysinit.ere.connections` declares each connection's SSH host, API endpoint,
namespace, storage class, and credential command in one place.

`task-context repo` lists actionable work for the current repository. TUI keys
`1` and `2` open the task URL and repository. Set `sysinit.tasks.urlAttribute`
for an integration-specific URL field. The TUI uses the effective focus report.
Daily export snapshots retain 14 copies by default; configure
`sysinit.tasks.backup.enable` and `.keep` to change that policy.

## Hide applications after a restart

Hammerspoon hides regular applications 15 seconds after its startup and
Accessibility initialization on a new boot. It records the boot UUID in its
settings. First installation records the current boot without hiding anything;
subsequent Hammerspoon reloads in the same boot do nothing. Applications remain
running and can be reopened normally. Applications launched after the delay
remain visible.
