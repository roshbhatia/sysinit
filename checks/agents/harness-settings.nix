{
  pkgs,
  home,
  darwinConfigurations,
  nixosConfigurations,
}:
let
  inherit (pkgs) lib;
  copilot = pkgs.sysinit.writeJSON "copilot-settings.json" home.sysinit.llm.managedFiles.copilot.content;
  darwin = darwinConfigurations.lv426.config;
  darwinHome = darwin.home-manager.users.${darwin.sysinit.user.username};
  systems = [
    darwin
    nixosConfigurations.arrakis.config
  ];
  hasReviewLink = lib.any (
    group: lib.any (hook: lib.hasSuffix "/bin/agent-review-link --hook" hook.command) group.hooks
  );
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
      ) == 9
    && builtins.any (
      group:
      (group.matcher or "") == "^apply_patch$"
      && builtins.any (hook: lib.hasSuffix "/bin/agent-review-link --hook" hook.command) group.hooks
    ) document.hooks.PostToolUse
    && hasReviewLink document.hooks.UserPromptSubmit
    && hasReviewLink document.hooks.Stop;
in
assert lib.any (package: lib.getName package == "goose-desktop") darwinHome.home.packages;
assert builtins.all managedHooksValid systems;
assert home.programs.claude-code.settings.permissions.defaultMode == "bypassPermissions";
assert builtins.any (
  group:
  group.matcher == "Edit|Write|MultiEdit|NotebookEdit"
  && builtins.any (hook: lib.hasSuffix "/bin/agent-review-link --hook" hook.command) group.hooks
) home.programs.claude-code.settings.hooks.PostToolUse;
assert hasReviewLink home.programs.claude-code.settings.hooks.UserPromptSubmit;
assert hasReviewLink home.programs.claude-code.settings.hooks.Stop;
assert !(home.programs.claude-code.settings ? dangerouslySkipPermissions);
assert !(home.programs.claude-code.settings ? disabledMcpServers);
assert home.programs.codex.settings.web_search == "live";
assert !(home.programs.codex.settings ? tools);
assert home.sysinit.llm.managedFiles.amp.content."amp.dangerouslyAllowAll";
assert home.sysinit.llm.managedFiles.devin.content.permission_mode == "dangerous";
(import ../lib/nushell.nix { inherit pkgs; }) {
  name = "harness-settings";
  script = ./harness-settings-setup.nu;
  sources = [ ../lib/process.nu ];
  arguments = [
    copilot
    home.xdg.configFile."gate/config.yaml".source
    "${pkgs.gate-providers}/share/gate/providers"
    ./harness-settings.nu
    "${pkgs.coreutils}/bin/timeout"
    home.xdg.configFile."acp/agents.json".source
    "${home.home.profileDirectory}/bin/goose"
  ];
  inputs = [
    pkgs.github-copilot-cli
    pkgs.yq-go
  ];
}
