{
  lib,
  pkgs,
  homeManagerLib,
  darwinConfigurations,
}:
let
  host = darwinConfigurations.lv426.config;
  home = host.home-manager.users.${host.sysinit.user.username};
  legacyHooks = import ../modules/home/programs/llm/harnesses/codex-retire-legacy-hooks.nix {
    inherit pkgs;
    lib = homeManagerLib;
  };
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
in
assert lib.hasInfix "codex-retire-legacy-hooks" legacyHooks.activation.data;
pkgs.runCommand "codex-legacy-hooks" { } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME/.codex"
  touch "$HOME/.codex/hooks.json.disabled"

  printf '%s\n' '[desktop]' 'external-agent-import-sync-enabled = true' \
    > "$HOME/.codex/config.toml"
  ${reconciler}/bin/sysinit-llm-reconcile
  grep -F 'external-agent-import-sync-enabled = false' "$HOME/.codex/config.toml"
  grep -F 'PATH = "/profile/bin:/usr/bin:/bin"' "$HOME/.codex/config.toml"

  sed -i 's/external-agent-import-sync-enabled = false/external-agent-import-sync-enabled = true/' \
    "$HOME/.codex/config.toml"
  ${reconciler}/bin/sysinit-llm-reconcile
  grep -F 'external-agent-import-sync-enabled = false' "$HOME/.codex/config.toml"

  printf '%s\n' '{"hooks":{"SessionStart":[{"hooks":[{"command":"claude-hook"}]}]}}' \
    > "$HOME/.codex/hooks.json"
  ${legacyHooks.script}
  test ! -e "$HOME/.codex/hooks.json"

  printf '%s\n' '{"hooks":{"Stop":[{"hooks":[{"command":"claude-hook"}]}]}}' \
    > "$HOME/.codex/hooks.json"
  ${legacyHooks.script}
  test ! -e "$HOME/.codex/hooks.json"
  test -e "$HOME/.codex/hooks.json.disabled"

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
  EOF
  ${bootstrapReconciler}/bin/sysinit-llm-reconcile
  ${lib.getExe pkgs.codex} mcp list > "$TMPDIR/mcp-list"
  grep -F 'node_repl' "$TMPDIR/mcp-list"

  touch "$out"
''
