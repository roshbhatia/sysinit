{
  inputs,
  ...
}:
[
  (import ./nvfetcher-sources.nix { })
  (import ./inputs.nix { inherit inputs; })
  (import ./python311.nix { })
  (import ./python313.nix { })
  (import ./crossplane.nix { })
  (import ./kubernetes-zeitgeist.nix { })
  (import ./go-enum.nix { })
  (import ./gomvp.nix { })
  (import ./mermaid-ascii.nix { })
  (import ./hererocks.nix { })
  (import ./openspec.nix { })
  (import ./deno.nix { })
  (import ./pi-coding-agent.nix { })
  (import ./crush.nix { })
  (import ./ast-grep.nix { })
  (import ./contextive.nix { })
  (import ./opa.nix { })
  (import ./ioskeleyMono.nix { })
  (import ./wumpusMono.nix { })
  (import ./bookerly.nix { })
  (import ./direnv.nix { })
  (import ./ginkgo.nix { })
  (import ./codex-acp.nix { })
  (import ./kvazaar.nix { })
  (import ./goose-cli.nix { })
  (import ./localias.nix { })
  (import ./alerter.nix { })
  (import ./sheets.nix { })
  (import ./mozilla.nix { inherit inputs; })
  (import ./nushell.nix { })
  # sdl3-3.4.10 testrwlock times out on i686-linux under emulation (used by lutris
  # via sdl2-compat); the rwlock test is a scheduler-sensitivity flake, not a
  # correctness issue.  Overlays propagate into pkgsi686Linux so one entry is enough.
  (_final: prev: {
    sdl3 = prev.sdl3.overrideAttrs (_old: {
      doCheck = false;
    });
  })
  # openldap-2.6.13 test017-syncreplication-refresh is a timing-sensitive flake
  (_final: prev: {
    openldap = prev.openldap.overrideAttrs (_old: {
      doCheck = false;
    });
  })
  # pipx-1.8.0 tests assert no space before @ in package specifiers but the
  # current packaging produces "name @ url" (PEP 440 canonical form).
  # Skip the affected tests — dontCheck doesn't stop pytestCheckHook in this
  # nixpkgs revision (it registers via preDistPhases, not checkPhase), so
  # disabledTests is the working knob.
  (_final: prev: {
    pipx = prev.pipx.overrideAttrs (old: {
      disabledTests = (old.disabledTests or [ ]) ++ [
        "test_fix_package_name"
        "test_parse_specifier_for_metadata"
      ];
    });
  })
  # fsspec test_expiry is a timing-sensitive flake — it asserts cache time
  # equality across a sleep, which races on loaded build machines.
  (_final: prev: {
    python313 = prev.python313.override {
      packageOverrides = _pyfinal: pyprev: {
        fsspec = pyprev.fsspec.overrideAttrs (old: {
          disabledTests = (old.disabledTests or [ ]) ++ [ "test_expiry" ];
        });
      };
    };
  })
  # kubernetes-helm-4.2.0: preCheck on Darwin tries to substituteInPlace
  # cmd/helm/dependency_build_test.go which doesn't exist in the 4.2.0 source tree.
  # Skip tests until nixpkgs fixes the Darwin sandbox workaround.
  (_final: prev: {
    kubernetes-helm = prev.kubernetes-helm.overrideAttrs (_old: {
      doCheck = false;
    });
  })
  # 1Password sometimes re-uploads the aarch64 zip with new bytes
  # without bumping the version, so nixpkgs' pinned hash no longer matches.
  # Override src with the current upstream hash until nixpkgs catches up.
  (_final: prev: {
    _1password-gui = prev._1password-gui.overrideAttrs (old: {
      src = prev.fetchurl {
        url = "https://downloads.1password.com/mac/1Password-${old.version}-aarch64.zip";
        hash = "sha256-bZD8LCLTGXRpNF/FqoSHvI69pquAcQGa1mdagWypgDU=";
      };
    });
  })
  # cctools-binutils-darwin-1010.6 ld crashes with Trace/BPT trap: 5 (SIGTRAP,
  # exit 133) on Darwin 25.x (macOS 26 Tahoe). The crash is intrinsic to the
  # cctools ld binary — not flag-specific. Patch the Makefile to remove the
  # arm64 deployment-target flag (cc-wrapper handles it) and inject -fuse-ld=
  # pointing at ld64.lld (LLVM's Mach-O linker) so clang bypasses cctools ld
  # entirely at link time.
  (final: prev: {
    sketchybar = prev.sketchybar.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages_latest.lld ];
      postPatch = ''
        sed -i '/CFLAGS+=-target arm64-apple-macos11/d' makefile
        sed -i 's|^CFLAGS   = |CFLAGS   = -fuse-ld=${final.llvmPackages_latest.lld}/bin/ld64.lld |' makefile
      '';
    });
  })
  # Same cctools crash for Rust packages: cargo invokes cc (clang-wrapper) as
  # the linker driver, which calls cctools ld. Pass -fuse-ld= via RUSTFLAGS so
  # clang routes through ld64.lld (LLVM's Mach-O linker) at the link step.
  (final: prev: {
    cargo-watch = prev.cargo-watch.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages_latest.lld ];
      RUSTFLAGS = "${old.RUSTFLAGS or ""} -C link-arg=-fuse-ld=${final.llvmPackages_latest.lld}/bin/ld64.lld";
    });
    mise = prev.mise.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages_latest.lld ];
      RUSTFLAGS = "${old.RUSTFLAGS or ""} -C link-arg=-fuse-ld=${final.llvmPackages_latest.lld}/bin/ld64.lld";
    });
  })
  # Same cctools crash: lima's CGO code links against Virtualization.framework on
  # Darwin 25.x (macOS 26 Tahoe). Use the official GitHub binary release until
  # nixpkgs ships a cctools version that handles the Tahoe linker constraints.
  (final: prev: {
    lima =
      let
        version = "2.1.4";
      in
      prev.stdenvNoCC.mkDerivation {
        pname = "lima";
        inherit version;

        src = prev.fetchzip {
          url = "https://github.com/lima-vm/lima/releases/download/v${version}/lima-${version}-Darwin-arm64.tar.gz";
          hash = "sha256-VLWiw0cvme0+wDd8f1C67hBe5d1jtwo9t6kWyJckjhI=";
          stripRoot = false;
        };

        dontFixup = true;

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r bin libexec share $out/
          runHook postInstall
        '';

        meta = prev.lima.meta // {
          platforms = [ "aarch64-darwin" ];
        };
      };

    # lima-full is lima with additional guest agents included; the binary
    # release already ships all guest agents, so both point to the same drv.
    lima-full = final.lima;
  })
]
