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
  (import ./hermes-agent.nix { inherit inputs; })
  (import ./opa.nix { })
  (import ./ioskeleyMono.nix { })
  (import ./wumpusMono.nix { })
  (import ./bookerly.nix { })
  (import ./direnv.nix { })
  (import ./ginkgo.nix { })
  (import ./codex-acp.nix { })
  (import ./kvazaar.nix { })
  (import ./goose-cli.nix { })
  (import ./sheets.nix { })
  (import ./mozilla.nix { inherit inputs; })
  (import ./nushell.nix { })
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
  # _1password-gui 8.12.24: 1Password re-uploaded the aarch64 zip with new bytes
  # without bumping the version, so nixpkgs' pinned hash no longer matches.
  # Override src with the current upstream hash until nixpkgs catches up.
  (_final: prev: {
    _1password-gui = prev._1password-gui.overrideAttrs (old: {
      src = prev.fetchurl {
        url = "https://downloads.1password.com/mac/1Password-${old.version}-aarch64.zip";
        hash = "sha256-6mCv+YbIXqp57t/E/3Xv+lsWDjlUmoOHQS/hh+ma0WY=";
      };
    });
  })
]
