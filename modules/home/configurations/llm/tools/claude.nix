{ lib, values, ... }:
let
  claudeConfig = import ../config/claude.nix;
  claudeEnabled = values.llm.claude.enabled or false;
in
lib.mkIf claudeEnabled {
  home.file = {
    "claude/settings.json" = {
      text = builtins.toJSON claudeConfig;
      force = true;
    };
  };
}
