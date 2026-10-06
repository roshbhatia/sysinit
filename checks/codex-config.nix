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
    (import ../modules/home/programs/llm/lib/managed-file.nix { inherit (pkgs) lib; }).mkReconciler
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
    (import ../modules/home/programs/llm/lib/managed-file.nix { inherit (pkgs) lib; }).mkReconciler
      {
        inherit pkgs;
        files.codex = home.sysinit.llm.managedFiles."codex-config.toml";
      };
  nativeToolsPython = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
in
assert home.programs.codex.settings.features.hooks;
assert builtins.all (event: home.programs.codex.settings.hooks.${event} != [ ]) [
  "SessionStart"
  "PreToolUse"
  "PostToolUse"
  "UserPromptSubmit"
  "Stop"
];
pkgs.runCommand "codex-config" { } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME/.codex"

  printf '%s\n' '[desktop]' 'external-agent-import-sync-enabled = true' \
    > "$HOME/.codex/config.toml"
  ${reconciler}/bin/sysinit-llm-reconcile
  grep -F 'external-agent-import-sync-enabled = false' "$HOME/.codex/config.toml"
  grep -F 'PATH = "/profile/bin:/usr/bin:/bin"' "$HOME/.codex/config.toml"

  sed -i 's/external-agent-import-sync-enabled = false/external-agent-import-sync-enabled = true/' \
    "$HOME/.codex/config.toml"
  ${reconciler}/bin/sysinit-llm-reconcile
  grep -F 'external-agent-import-sync-enabled = false' "$HOME/.codex/config.toml"

  export HOME="$TMPDIR/bootstrap-home"
  mkdir -p "$HOME/.codex"
  cat > "$HOME/.codex/.config.toml.nix-base" <<'EOF'
  [mcp_servers.computer-use]
  enabled = false
  [mcp_servers.cua_repl]
  enabled = false
  [mcp_servers.node_repl]
  enabled = false
  EOF
  cat > "$HOME/.codex/config.toml" <<'EOF'
  [mcp_servers.computer-use]
  enabled = false
  command = "/user/computer-use"
  [mcp_servers.cua_repl]
  enabled = false
  command = "/user/cua"
  [mcp_servers.node_repl]
  enabled = false
  command = "/app/node_repl"
  [mcp_servers.node_repl.env]
  NATIVE_PIPE = "/app/pipe"
  [plugins."computer-use@openai-bundled"]
  enabled = false
  [plugins."browser@openai-bundled"]
  enabled = false
  [features]
  js_repl = false
  EOF
  ${lib.getExe nativeToolsPython} ${../modules/home/programs/llm/harnesses/codex-native-tools.py}
  ${bootstrapReconciler}/bin/sysinit-llm-reconcile
  ${lib.getExe pkgs.codex} mcp list > "$TMPDIR/mcp-list"
  grep -F 'node_repl' "$TMPDIR/mcp-list"
  ${lib.getExe nativeToolsPython} - <<'PY'
  import os
  from pathlib import Path
  import tomlkit
  path = Path(os.environ["HOME"]) / ".codex/config.toml"
  document = tomlkit.parse(path.read_text())
  servers = document["mcp_servers"]
  assert "computer-use" not in servers
  assert "cua_repl" not in servers
  assert servers["node_repl"]["command"] == "/app/node_repl"
  assert servers["node_repl"]["env"]["NATIVE_PIPE"] == "/app/pipe"
  assert servers["node_repl"].get("enabled", True)
  assert not document["plugins"]["computer-use@openai-bundled"]["enabled"]
  assert document["plugins"]["browser@openai-bundled"]["enabled"]
  assert "js_repl" not in document["features"]
  document["plugins"]["browser@openai-bundled"]["enabled"] = False
  path.write_text(tomlkit.dumps(document))
  PY
  ${lib.getExe nativeToolsPython} ${../modules/home/programs/llm/harnesses/codex-native-tools.py}
  grep -A 1 '\[plugins."browser@openai-bundled"\]' "$HOME/.codex/config.toml" | grep -F 'enabled = false'

  touch "$out"
''
