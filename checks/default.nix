{ pkgs, lib, ... }:
# ast-grep is here so CI can reach it by name; `.githooks/pre-commit` runs the
# same scan. The rest are here rather than in the hook, whose skip-when-absent
# idiom would make them no-ops on a box missing their inputs.
{
  agent-identity-fork = import ./agent-identity-fork.nix { inherit pkgs lib; };
  ast-grep-nix-rules = import ./ast-grep-nix-rules.nix { inherit pkgs; };
  hunk-agent-context = import ./hunk-agent-context.nix { inherit pkgs lib; };
  llm-skill-destinations = import ./llm-skill-destinations.nix { inherit pkgs lib; };
  wezterm-lua-globals = import ./wezterm-lua-globals.nix { inherit pkgs; };
  wezterm-rollup = import ./wezterm-rollup.nix { inherit pkgs; };
}
