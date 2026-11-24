{
  lib,
  pkgs,
  home,
}:
let
  declaredConfig = pkgs.writeText "codex-config.toml" ''
    [desktop]
    external-agent-import-sync-enabled = false

    [shell_environment_policy.set]
    PATH = "/profile/bin:/usr/bin:/bin"
  '';
  reconciler =
    (import ../../modules/home/programs/llm/lib/managed-file.nix { inherit (pkgs) lib; }).mkReconciler
      {
        inherit pkgs;
        files.codex = {
          enable = true;
          path = ".codex/config.toml";
          format = "toml";
          content = { };
          contentFile = declaredConfig;
          createIfMissing = true;
          enforce = [
            [
              "desktop"
              "external-agent-import-sync-enabled"
            ]
          ];
          schema = null;
          retire = [ ];
        };
      };
  bootstrapReconciler =
    (import ../../modules/home/programs/llm/lib/managed-file.nix { inherit (pkgs) lib; }).mkReconciler
      {
        inherit pkgs;
        files.codex = home.sysinit.llm.managedFiles."codex-config.toml";
      };

in
assert home.programs.codex.settings.features.hooks;
assert builtins.all (event: home.programs.codex.settings.hooks.${event} != [ ]) [
  "PreToolUse"
  "PostToolUse"
  "UserPromptSubmit"
  "Stop"
];
(import ../lib/nushell.nix { inherit pkgs; }) {
  name = "codex-config";
  script = ./codex-config.nu;
  sources = [ ../lib/process.nu ];
  arguments = [
    "${reconciler}/bin/sysinit-llm-reconcile"
    "${bootstrapReconciler}/bin/sysinit-llm-reconcile"
    ../../modules/home/programs/llm/harnesses/codex-native-tools.nu
    (lib.getExe' pkgs.coreutils "chmod")
    (lib.getExe pkgs.codex)
  ];
}
