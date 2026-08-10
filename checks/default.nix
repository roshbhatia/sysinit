{ pkgs, lib, ... }:
# Five checks. The rest left `nix flake check` because a check that only runs
# when someone remembers to run the flake reports a regression long after the
# commit that caused it. ast-grep stays here so CI can reach it by name, and
# `.githooks/pre-commit` runs the same scan on every commit.
#
# The two note checks stay here rather than in the hook for the opposite reason:
# the hook's idiom is skip-when-absent, and a guard that silently skips is the
# failure they exist to catch. Under `checks/` their inputs are present by
# construction.
{
  # Phase 10's STOP gate. Behavioral, because the property is control flow and
  # the gated call reads exactly like the ungated one.
  agent-identity-fork = import ./agent-identity-fork.nix { inherit pkgs lib; };
  ast-grep-nix-rules = import ./ast-grep-nix-rules.nix { inherit pkgs; };
  hunk-agent-context = import ./hunk-agent-context.nix { inherit pkgs lib; };
  llm-skill-destinations = import ./llm-skill-destinations.nix { inherit pkgs lib; };
  wezterm-rollup = import ./wezterm-rollup.nix { inherit pkgs; };
}
