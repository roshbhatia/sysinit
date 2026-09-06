{
  lib,
  pkgs,
  homeManagerLib,
}:
let
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

  touch "$out"
''
