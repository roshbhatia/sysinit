{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  cursorConfig = builtins.toJSON {
    version = 1;
    permissions = {
      # Allow all shell commands — wildcard bypasses per-command prompts. The
      # deny list is what makes that safe: it carries the same destructive-command
      # globs every other harness denies, so `git reset --hard` and friends are
      # blocked here too rather than sailing through the wildcard.
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

  # Cursor MDC rule files installed at ~/.cursor/rules/<name>.mdc.
  # Each MDC has frontmatter declaring either `alwaysApply: true` OR `globs:`,
  # never both. Assertion below enforces this.
  cursorRules = {
    always = ./cursor-rules/always.mdc;
    nix = ./cursor-rules/nix.mdc;
    markdown = ./cursor-rules/markdown.mdc;
  };

  # Build-time check: a rule MDC must not declare both alwaysApply and globs.
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
in
{
  home.file = {
    ".cursor/cli-config.json" = {
      text = cursorConfig;
      force = true;
    };
    ".cursor/mcp.json" = {
      text = cursorMcpConfig;
      force = true;
    };
  }
  // ruleFiles;
}
