{
  pkgs,
  lib,
  system,
}:
let
  notifyIcons = (import ../modules/home/programs/llm/runtime { inherit pkgs lib; }).icons;

  managedFile = import ../modules/home/programs/llm/lib/managed-file.nix { inherit lib; };

  check =
    path:
    import path {
      inherit
        pkgs
        lib
        system
        notifyIcons
        managedFile
        ;
    };
in
{
  agent-review-readiness = check ./agent-review-readiness.nix;
  agent-sessions-rollup = check ./agent-sessions-rollup.nix;
  check-bodies-shellcheck = check ./check-bodies-shellcheck.nix;
  citelock = check ./citelock.nix;
  destructive-guard-fixtures = check ./destructive-guard-fixtures.nix;
  diffnote-roundtrip = check ./diffnote-roundtrip.nix;
  exit-code-guard-blocks = check ./exit-code-guard-blocks.nix;
  llm-asset-paths-resolve = check ./llm-asset-paths-resolve.nix;
  lua-parses = check ./lua-parses.nix;
  managed-file-merge3 = check ./managed-file-merge3.nix;
  managed-file-reconcile = check ./managed-file-reconcile.nix;
  notify-defect-regressions = check ./notify-defect-regressions.nix;
  opencode-config-schema = check ./opencode-config-schema.nix;
  openspec-default-schema = check ./openspec-default-schema.nix;
  pi-no-theme-writer = check ./pi-no-theme-writer.nix;
  pi-settings-keys-exist = check ./pi-settings-keys-exist.nix;
  pi-shell-prefix-loads-aliases = check ./pi-shell-prefix-loads-aliases.nix;
  schema-templates-conform = check ./schema-templates-conform.nix;
  shell-scripts-shellcheck = check ./shell-scripts-shellcheck.nix;
  skill-render-shape = check ./skill-render-shape.nix;
  wezterm-chord-collisions = check ./wezterm-chord-collisions.nix;
  agent-chord-collisions = check ./agent-chord-collisions.nix;
  zsh-fragments-parse = check ./zsh-fragments-parse.nix;
}
