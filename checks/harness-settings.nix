{
  pkgs,
  home,
  darwinConfigurations,
  nixosConfigurations,
}:
let
  inherit (pkgs) lib;
  copilot = pkgs.sysinit.writeJSON "copilot-settings.json" home.sysinit.llm.managedFiles.copilot.content;
  systems = [
    darwinConfigurations.lv426.config
    nixosConfigurations.arrakis.config
  ];
  managedHooksValid =
    system:
    let
      user = system.home-manager.users.${system.sysinit.user.username};
      document = builtins.fromJSON system.environment.etc."codex/hooks.json".text;
    in
    system.sysinit.codex.systemHooks.enable
    && (user.programs.codex.settings.hooks or { }) == { }
    &&
      builtins.length (
        lib.concatMap (group: group.hooks) (lib.concatLists (builtins.attrValues document.hooks))
      ) == 7
    && builtins.any (
      group:
      (group.matcher or "") == "^apply_patch$"
      && builtins.any (hook: lib.hasSuffix "/bin/agent-review-link --hook" hook.command) group.hooks
    ) document.hooks.PostToolUse;
in
assert builtins.all managedHooksValid systems;
assert home.programs.claude-code.settings.permissions.defaultMode == "bypassPermissions";
assert builtins.any (
  group:
  group.matcher == "Edit|Write|MultiEdit|NotebookEdit"
  && builtins.any (hook: lib.hasSuffix "/bin/agent-review-link --hook" hook.command) group.hooks
) home.programs.claude-code.settings.hooks.PostToolUse;
assert !(home.programs.claude-code.settings ? dangerouslySkipPermissions);
assert !(home.programs.claude-code.settings ? disabledMcpServers);
assert home.programs.codex.settings.web_search == "live";
assert !(home.programs.codex.settings ? tools);
assert home.sysinit.llm.managedFiles.fx.content.auto_upgrade == false;
assert home.sysinit.llm.managedFiles.amp.content."amp.dangerouslyAllowAll";
assert home.sysinit.llm.managedFiles.devin.content.permission_mode == "dangerous";
assert home.sysinit.llm.managedFiles.fx.content.permission_mode == "full-access";
(import ./lib.nix { inherit pkgs; }) {
  name = "harness-settings";
  script = "harness-settings-setup.nu";
  arguments = [
    copilot
    home.xdg.configFile."gate/config.yaml".source
    "${pkgs.gate-providers}/share/gate/providers"
    ./harness-settings.nu
    "${pkgs.coreutils}/bin/timeout"
  ];
  inputs = [
    pkgs.github-copilot-cli
    pkgs.yq-go
  ];
}
