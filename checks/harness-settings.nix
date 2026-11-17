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
      ) == 6;
in
assert builtins.all managedHooksValid systems;
assert home.programs.claude-code.settings.permissions.defaultMode == "bypassPermissions";
assert !(home.programs.claude-code.settings ? dangerouslySkipPermissions);
assert !(home.programs.claude-code.settings ? disabledMcpServers);
assert home.programs.codex.settings.web_search == "live";
assert !(home.programs.codex.settings ? tools);
assert home.sysinit.llm.managedFiles.fx.content.auto_upgrade == false;
assert home.sysinit.llm.managedFiles.amp.content."amp.dangerouslyAllowAll";
assert home.sysinit.llm.managedFiles.devin.content.permission_mode == "dangerous";
assert home.sysinit.llm.managedFiles.fx.content.permission_mode == "full-access";
pkgs.runCommand "harness-settings"
  {
    nativeBuildInputs = [
      pkgs.nushell
      pkgs.github-copilot-cli
      pkgs.yq-go
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export COPILOT_HOME="$HOME/.copilot"
    mkdir -p "$COPILOT_HOME"
    cp ${copilot} "$COPILOT_HOME/settings.json"
    copilot config --list --json > parsed.json

    yq -o=json '
      .providers.directory = "${pkgs.gate-providers}/share/gate/providers"
      | .log = strenv(TMPDIR) + "/gate.jsonl"
      | .chains = {"PreToolUse": (.chains.PreToolUse | map(select(.provider == "bash-guard")))}
    ' ${home.xdg.configFile."gate/config.yaml".source} > gate.json
    export GATE_CONFIG="$PWD/gate.json"

    nu --no-config-file ${./harness-settings.nu} ${pkgs.coreutils}/bin/timeout
    touch "$out"
  ''
