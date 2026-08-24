{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  cursorSettings = {
    version = 1;
    permissions = {
      allow = [ "Shell(.*)" ];
      deny = llmLib.allowlist.formatDestructiveForCursor llmLib.allowlist.destructiveDenyGlobs;
    };
    editor = {
      vimMode = true;
    };
    network = {
      useHttp1ForAgent = true;
    };
  };

  cursorMcpConfig = builtins.toJSON {
    mcpServers = llmLib.mcp.formatForCursor kit.mcpServers.servers;
  };

  alwaysMdc = pkgs.writeText "cursor-always.mdc" ''
    ---
    description: Repo-wide conventions and prohibitions, generated from instructions.nix.
    alwaysApply: true
    ---

    ${kit.mkInstructionsWithStyle {
      harness = "cursor";
      skillsRoot = "~/.claude/skills";
    }}
  '';

  cursorRules = {
    nix = ./rules/nix.mdc;
    markdown = ./rules/markdown.mdc;
  };

  # managedFiles paths are relative to the home directory.
  cursorConfigDir = "${lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome}/cursor";

  ruleFiles = lib.mapAttrs' (
    name: path:
    lib.nameValuePair ".cursor/rules/${name}.mdc" {
      source = path;
      force = true;
    }
  ) cursorRules;

in
{

  # cursor-agent resolves its config dir as CURSOR_CONFIG_DIR, then
  # $XDG_CONFIG_HOME/cursor, then ~/.cursor, with no platform gate. This repo
  # exports XDG_CONFIG_HOME, so the second branch always wins and a file under
  # ~/.cursor is never read: the deny list here was inert. `rules/` and
  # `mcp.json` stay below, because cursor reads those from the home directory
  # rather than from the config dir.
  sysinit.llm.managedFiles.cursor = {
    path = "${cursorConfigDir}/cli-config.json";
    format = "json";
    content = cursorSettings;
    enforce = [ "permissions" ];
  };
  home.file = {
    ".cursor/rules/always.mdc" = {
      source = alwaysMdc;
      force = true;
    };
    ".cursor/mcp.json" = {
      text = cursorMcpConfig;
      force = true;
    };
  }
  // ruleFiles;
}
