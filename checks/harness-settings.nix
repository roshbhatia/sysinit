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
pkgs.runCommand "harness-settings"
  {
    nativeBuildInputs = [
      pkgs.python3
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

    python3 - <<'PY'
    import json
    import os
    from pathlib import Path
    import subprocess

    parsed = json.loads(Path("parsed.json").read_text())
    assert parsed["theme"] == "default"
    hook = parsed["hooks"]["preToolUse"][0]
    assert hook["_vsCodeCompat"] == "PreToolUse", hook
    assert hook["matcher"] == "Bash", hook
    for command, expected in [("printf fixture", 0), ("git reset --hard", 2)]:
        result = subprocess.run(
            [hook["bash"]],
            input=json.dumps({
                "hook_event_name": "PreToolUse",
                "session_id": "harness-settings-test",
                "cwd": os.getcwd(),
                "tool_name": "Bash",
                "tool_input": {"command": command},
            }),
            text=True, capture_output=True, timeout=15,
            env={**os.environ, "PATH": "/usr/bin:/bin"},
        )
        assert result.returncode == expected, (command, result.returncode, result.stderr)
        if expected:
            assert "prohibited" in result.stderr, result.stderr
    print("Native Copilot hook parsing and real guard allow/deny passed")
    PY
    touch "$out"
  ''
