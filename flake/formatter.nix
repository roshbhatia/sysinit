{ nixpkgs, systems }:
nixpkgs.lib.genAttrs systems (
  system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
  in
  pkgs.writeShellApplication {
    name = "sysinit-fmt";
    runtimeInputs = with pkgs; [
      git
      treefmt
      nixfmt
      shfmt
      stylua
      go
      ruff
      nufmt
      fish
      taplo
      prettier
      clang-tools
      cue
    ];
    text = builtins.readFile ../hack/format.sh;
  }
)
