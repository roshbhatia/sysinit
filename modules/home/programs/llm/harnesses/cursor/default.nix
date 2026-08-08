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

  validateMdc =
    name: path:
    let
      content = builtins.readFile path;
      hasAlwaysApply = lib.hasInfix "alwaysApply: true" content;
      hasGlobs = lib.hasInfix "globs:" content;
    in
    if hasAlwaysApply && hasGlobs then
      throw "cursor.nix: rule '${name}' declares both alwaysApply and globs; pick one"
    else
      path;

  ruleFiles = lib.mapAttrs' (
    name: path:
    lib.nameValuePair ".cursor/rules/${name}.mdc" {
      source = validateMdc name path;
      force = true;
    }
  ) cursorRules;
  generatedFacts = [
    "never push"
    "openspec 1."
    "200 lines"
    "## Stack"
    "## Commands"
  ];

  authoredBodies = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (_: path: builtins.readFile path) cursorRules
  );

  duplicatedFacts = lib.filter (
    f: lib.hasInfix (lib.toLower f) (lib.toLower authoredBodies)
  ) generatedFacts;

  assertNoDuplicatedFacts =
    if duplicatedFacts != [ ] then
      throw "cursor.nix: an authored rule file restates ${lib.concatStringsSep ", " duplicatedFacts}, which instructions.nix already renders. Remove it from the rule file."
    else
      true;
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
  // (
    assert assertNoDuplicatedFacts;
    ruleFiles
  );
}
