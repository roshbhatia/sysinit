{ pkgs }:
let
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
in
{
  update-flakes = nativeCheck {
    name = "update-flakes-check";
    inputs = [ pkgs.git ];
    commands = [
      [
        "nu"
        "--no-config-file"
        ../../hack/test-update-flakes.nu
        ../../hack/update-flakes.nu
        ../../hack/fixtures/update-flakes-command.nu
      ]
    ];
  };

  nvfetcher-sources = import ./nvfetcher-sources.nix { inherit pkgs; };

  inherit (pkgs) leaf-reader;

  opentelemetry-collector = pkgs.opentelemetry-collector-contrib.tests.version;

  onepassword = import ./onepassword.nix { inherit pkgs; };

  utility-contracts = import ./utility-contracts.nix { inherit pkgs; };

  generated-format = import ./generated-format.nix { inherit pkgs; };

  go-tests = pkgs.sysinit-gotools;

  ast-grep-installed-rules = import ./ast-grep.nix { inherit pkgs; };
}
