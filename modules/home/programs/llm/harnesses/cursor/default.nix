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

  ruleFiles = lib.mapAttrs' (
    name: path:
    lib.nameValuePair ".cursor/rules/${name}.mdc" {
      source = path;
      force = true;
    }
  ) cursorRules;

in
{

  sysinit.llm.managedFiles.cursor = {
    path = ".cursor/cli-config.json";
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
