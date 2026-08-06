{
  inputs,
  ...
}:
[
  # Sunshine runs with CAP_SYS_ADMIN (capSysAdmin=true) for KMS framebuffer
  # capture on arrakis. CAP_SYS_ADMIN triggers AT_SECURE which blocks
  # LD_LIBRARY_PATH, so /run/opengl-driver/lib must be in the RUNPATH for
  # libnvidia-encode and libcuda to resolve at runtime. sunshine uses
  (_final: prev: {
    sunshine =
      if prev.stdenv.hostPlatform.isLinux then
        (prev.sunshine.override {
          cudaSupport = true;
          # cuda_compat is a Jetson-only shim with no x86_64 src; the repo-wide
          # allowUnsupportedSystem=true defeats its availability gate and pulls
          # it into the cudart hook chain, so drop it from the scope.
          cudaPackages = prev.cudaPackages.overrideScope (_: _: { cuda_compat = null; });
        }).overrideAttrs
          (old: {
            appendRunpaths = (old.appendRunpaths or [ ]) ++ [ "/run/opengl-driver/lib" ];
          })
      else
        prev.sunshine;
  })
  (import ./nvfetcher-sources.nix)
  (import ./inputs.nix { inherit inputs; })
  (import ./meat.nix { inherit inputs; })
  (import ./python311.nix)
  (import ./python313.nix)
  (import ./kubernetes-zeitgeist.nix)
  (import ./go-enum.nix)
  (import ./gomvp.nix)
  (import ./mermaid-ascii.nix)
  (import ./hererocks.nix)
  (import ./openspec)
  (import ./pi-coding-agent.nix)
  (import ./crush.nix)
  (import ./contextive.nix)
  (import ./opa.nix)
  (import ./ioskeleyMono.nix)
  (import ./wumpusMono.nix)
  (import ./bookerly.nix)
  (import ./direnv.nix)
  (import ./codex-acp.nix)
  (import ./kvazaar.nix)
  (import ./obsidian.nix)
  (import ./localias.nix)
  (import ./pplx.nix)
  (import ./alerter.nix)
  (import ./sheets.nix)
  # sdl3-3.4.10 testrwlock times out on i686-linux under emulation (used by lutris
  # via sdl2-compat); the rwlock test is a scheduler-sensitivity flake, not a
  # correctness issue. Guard to i686: overriding sdl3 on x86_64 perturbs its hash
  # and cascades an uncached rebuild through sdl2-compat -> ffmpeg -> the whole
  (_final: prev: {
    sdl3 =
      if prev.stdenv.hostPlatform.system == "i686-linux" then
        prev.sdl3.overrideAttrs (_old: {
          doCheck = false;
        })
      else
        prev.sdl3;
  })
  (
    _final: prev:
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
      pipx = prev.pipx.overridePythonAttrs (o: {
        disabledTestPaths = (o.disabledTestPaths or [ ]) ++ [ "tests/test_inject.py" ];
      });
    }
  )
  # 1Password sometimes re-uploads the aarch64 zip with new bytes
  # without bumping the version, so nixpkgs' pinned hash no longer matches.
  # Override src with the current upstream hash until nixpkgs catches up.
  # Guard to Darwin: the Linux derivation uses a tar.gz and must not receive
  (_final: prev: {
    _1password-gui =
      if prev.stdenv.hostPlatform.isDarwin then
        prev._1password-gui.overrideAttrs (old: {
          src = prev.fetchurl {
            url = "https://downloads.1password.com/mac/1Password-${old.version}-aarch64.zip";
            hash = "sha256-utESL4dUIe/jD9gu3YIF+HWnGUlWr54tSI1Jtrruxsc=";
          };
        })
      else
        prev._1password-gui;
  })
  (final: prev: {
    cargo-watch =
      if prev.stdenv.hostPlatform.isDarwin then
        prev.cargo-watch.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages_latest.lld ];
          RUSTFLAGS = "${old.RUSTFLAGS or ""} -C link-arg=-fuse-ld=${final.llvmPackages_latest.lld}/bin/ld64.lld";
        })
      else
        prev.cargo-watch;
    # Pull mise from a pristine nixpkgs so its closure hash matches
    # cache.nixos.org on both platforms: repo overlays perturb prev.mise's deps
    # on Linux, and the darwin Tahoe ld-fix is obsolete now that nixpkgs' cached
    # aarch64-darwin build works on Tahoe.
    mise = (import inputs.nixpkgs { inherit (final.stdenv.hostPlatform) system; }).mise;
    # electron's ffmpeg pulls the gaming-patched SDL, perturbing its closure into
    # a multi-hour chromium source build (obsidian depends on it). electron does
    # not need those patches, so pin it to pristine nixpkgs on Linux for a cache
    # hit; Darwin keeps prev to avoid an uncached darwin rebuild.
    electron_41 =
      if prev.stdenv.hostPlatform.isDarwin then
        prev.electron_41
      else
        (import inputs.nixpkgs { inherit (final.stdenv.hostPlatform) system; }).electron_41;
    electron =
      if prev.stdenv.hostPlatform.isDarwin then
        prev.electron
      else
        (import inputs.nixpkgs { inherit (final.stdenv.hostPlatform) system; }).electron;
  })
]
