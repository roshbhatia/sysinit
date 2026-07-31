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

  # The always-applied rule is GENERATED. Its body was authored prose that
  # summarized the shared context and then drifted from it: it stated
  # `openspec 1.3.0` against a 1.6.0 overlay, and carried "never push to main",
  # which this repository does not hold. Only the frontmatter stays authored,
  # because that is a Cursor loader concern and not a rule.
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

  # Cursor MDC rule files installed at ~/.cursor/rules/<name>.mdc.
  # Each MDC has frontmatter declaring either `alwaysApply: true` OR `globs:`,
  # never both. Assertion below enforces this.
  #
  # nix.mdc and markdown.mdc stay authored: they carry glob-scoped domain rules
  # that the cross-repository context deliberately excludes.
  cursorRules = {
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
  # No authored rule file may restate a fact the generator already renders.
  # Restating one creates a second place to drift, which is exactly how
  # always.mdc came to claim openspec 1.3.0 and a prohibition this repository
  # does not hold.
  generatedFacts = [
    "never push"
    "openspec 1."
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
  home.file = {
    ".cursor/rules/always.mdc" = {
      source = alwaysMdc;
      force = true;
    };
    ".cursor/cli-config.json" = {
      text = cursorConfig;
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
