---
description: Checks whether an entry in `overlays/` still earns its keep, by comparing the pristine package against the overridden one on cache.nixos.org. Use before adding a test-skip or a link-failure workaround, when a switch rebuilds a package from source that should have been substituted, or when asked why the build is slow or which overlays are obsolete.
allowed-tools: Read Glob Grep Bash(nix:*) Bash(curl:*) Bash(basename:*) Bash(cut:*)
model: sonnet
---

# Overlay cache audit

An overlay entry that works around a broken build is temporary by nature, but
nothing expires it. Two kinds go stale:

1. Test-disabling: `doCheck = false` or `disabledTests`, added when a fresh
   nixpkgs revision built from source and hit a flaky test.
2. Tahoe `cctools-ld` fixes: an `overrideAttrs` adding `ld64.lld`, or a swap to
   a GitHub binary. Both were added when a local Darwin build crashed at link
   time on macOS 26.

Both become waste once Hydra catches up. Hydra builds Darwin on an older macOS
and its binary runs on Tahoe, so the pristine package gets cached. The override
then changes the derivation hash and nothing more, which forces a local source
build of a package that was already available.

<examples>
<example>
<bad>The build fails at link time, so add an `ld64.lld` override to `overlays/`.</bad>
<good>The build fails at link time. Check whether the pristine path substitutes from cache.nixos.org first; add the override only if it does not.</good>
</example>
<example>
<bad>The overlay entry still exists, so it is still needed.</bad>
<good>The pristine path for `lima` is cached, so the override only costs a source build. Delete it.</good>
</example>
</examples>

## Audit one package

Run all three steps. `<pkg>` is the attribute name, `<nixpkgs-store-path>` is
the locked nixpkgs path from `nix flake metadata`.

1. Pristine path, evaluated outside this flake's overlays:

```bash
nix eval --raw --impure --expr '(import <nixpkgs-store-path> {
  system = "aarch64-darwin";
  config.allowUnfree = true;
  config.allowUnsupportedSystem = true;
}).<pkg>.outPath'
```

2. In-config path, with the overlays applied. Use `lv426` for
`aarch64-darwin` and `arrakis` for `x86_64-linux`; both build from the local
working tree:

```bash
nix eval --raw '.#darwinConfigurations.lv426.pkgs.<pkg>.outPath'
```

3. Cached, for each path. The hash is the first field of the basename:

```bash
curl -sf https://cache.nixos.org/<hash>.narinfo > /dev/null && echo CACHED || echo MISSING
```

## Read the result

| Pristine | Overridden | Verdict |
| --- | --- | --- |
| CACHED | MISSING | Obsolete. Remove the override, or guard it to the platform that still needs it. |
| CACHED | CACHED | Harmless. The override changed nothing that affects the hash. |
| MISSING | MISSING | Keep. The package is not on Hydra for this platform. |

## Keep list

These are MISSING pristine and stay. `cargo-watch` is Tahoe and absent from
Hydra. `_1password-gui` is unfree and never cached. `future` is a functional
`disabled = false` force-enable, not a workaround. So are the platform-guarded
`sunshine`, `sdl3`, and `electron`.

## Traps

- `python313.override { packageOverrides = ... }` re-hashes the entire Python
  set. One test-skip cascades to every `python313Packages.*`, so audit the
  fixpoint, not the single package.
- Custom and nvfetcher packages (openspec, localias, claude-code) are never on
  `cache.nixos.org`. A MISSING result there proves nothing about the override.
  Their cache is `roshbhatia.cachix.org`; see `AGENTS.md`.
- Report the verdict and the evidence. Removing an overlay entry is the owner's
  call, and a wrong removal reintroduces a build failure that was real.
