{
  pkgs,
  home,
  darwinConfigurations,
  nixosConfigurations,
}:
let
  inherit (pkgs) lib;
  copilot = pkgs.sysinit.writeJSON "copilot-settings.json" home.sysinit.managedFiles.copilot.content;
  darwin = darwinConfigurations.lv426.config;
  darwinHome = darwin.home-manager.users.${darwin.sysinit.user.username};
  systems = [
    darwin
    nixosConfigurations.arrakis.config
  ];
  hasReviewLink =
    harness:
    lib.any (
      group:
      lib.any (
        hook: lib.hasSuffix "/bin/agent-review-link --hook --harness ${harness}" hook.command
      ) group.hooks
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
      && builtins.any (
        hook: lib.hasSuffix "/bin/agent-review-link --hook --harness codex" hook.command
      ) group.hooks
    ) document.hooks.PostToolUse
    && hasReviewLink "codex" document.hooks.UserPromptSubmit
    && hasReviewLink "codex" document.hooks.Stop;
in
assert lib.any (package: lib.getName package == "goose-desktop") darwinHome.home.packages;
assert darwinHome.programs.codex.settings.desktop."code-review-sidebar-layout" == "compact";
assert !(darwinHome.programs.codex.settings.plugins ? "computer-use@openai-bundled");
assert darwinHome.sysinit.managedFiles.claude-json.content.deepLinkTerminal == "WezTerm";
assert
  darwinHome.sysinit.managedFiles.claude-desktop.content.preferences == {
    quickEntryShortcut = "off";
    quickEntryDictationShortcut = "off";
  };
assert
  darwinHome.sysinit.managedFiles.goose-desktop.content.keyboardShortcuts == {
    focusWindow = null;
    quickLauncher = null;
  };
assert builtins.all
  (chord: !(builtins.hasAttr chord darwin.sysinit.darwin.keybindings.reservedChords))
  [
    "cmd+enter"
    "cmd+shift+enter"
  ];
assert darwin.sysinit.darwin.keybindings.reservedChords."cmd+alt+enter" == "Handy transcribe";
assert
  darwinHome.sysinit.managedFiles.handy.content.settings.bindings.transcribe.current_binding
  == "command+option+enter";
assert builtins.elem "WezTerm" darwinHome.sysinit.managedFiles.handy.content.settings.custom_words;
assert builtins.all managedHooksValid systems;
assert home.programs.claude-code.settings.permissions.defaultMode == "bypassPermissions";
assert builtins.any (
  group:
  group.matcher == "Edit|Write|MultiEdit|NotebookEdit"
  && builtins.any (
    hook: lib.hasSuffix "/bin/agent-review-link --hook --harness claude" hook.command
  ) group.hooks
) home.programs.claude-code.settings.hooks.PostToolUse;
assert hasReviewLink "claude" home.programs.claude-code.settings.hooks.UserPromptSubmit;
assert hasReviewLink "claude" home.programs.claude-code.settings.hooks.Stop;
assert !(home.programs.claude-code.settings ? dangerouslySkipPermissions);
assert !(home.programs.claude-code.settings ? disabledMcpServers);
assert home.programs.codex.settings.web_search == "live";
assert !(home.programs.codex.settings ? tools);
assert home.sysinit.managedFiles.amp.content."amp.dangerouslyAllowAll";
assert home.sysinit.managedFiles.devin.content.permission_mode == "dangerous";
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
