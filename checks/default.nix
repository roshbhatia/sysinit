{ pkgs, ... }:
# One check remains. The rest left `nix flake check` because a check that only
# runs when someone remembers to run the flake reports a regression long after
# the commit that caused it. ast-grep stays here so CI can reach it by name,
# and `.githooks/pre-commit` runs the same scan on every commit.
{
  ast-grep-nix-rules = import ./ast-grep-nix-rules.nix { inherit pkgs; };
}
