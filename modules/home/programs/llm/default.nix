{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  skills = import ./skills.nix { inherit pkgs; };

  # Claude Code standard path - most tools can read from here
  skillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { source = path; }
  ) skills.allSkills;

  # Helper scripts shipped beside a skill's SKILL.md; executable so the skill
  # can invoke them by path.
  skillScriptFiles = lib.mapAttrs' (
    relPath: src:
    lib.nameValuePair ".claude/skills/${relPath}" {
      source = src;
      executable = true;
    }
  ) skills.skillExtraFiles;

  # Skills shipped by specutil itself; pulled straight from the flake source
  # so they stay in sync whenever the lock is bumped (nix flake update specutil).
  specutilSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { source = path; }
  ) inputs.specutil.lib.skills;

  # Upstream ast-grep skills, vendored from the pinned `ast-grep-skills` input.
  # Installed verbatim: these are the tool author's own guides, so restating
  # them in skills/ would be the drift this repo's sync rules exist to prevent.
  # The directory name is the skill name, and upstream's outline skill declares
  # `name: ast-grep-outline`, so its directory must match that, not "outline".
  astGrepSkillRoot = "${inputs.ast-grep-skills}/ast-grep/skills";
  astGrepSkillFiles = {
    "ast-grep/SKILL.md" = "${astGrepSkillRoot}/ast-grep/SKILL.md";
    "ast-grep/references/rule_reference.md" =
      "${astGrepSkillRoot}/ast-grep/references/rule_reference.md";
    "ast-grep-outline/SKILL.md" = "${astGrepSkillRoot}/outline/SKILL.md";
  };

  vendoredSkillFilesFor =
    root:
    lib.mapAttrs' (rel: src: lib.nameValuePair "${root}/${rel}" { source = src; }) astGrepSkillFiles;

  # Amp validates skill frontmatter against a fixed allowlist and errors on any
  # key outside it, so it gets its own render rather than reading the Claude
  # tree. config/amp.nix turns off Amp's .claude/skills auto-load to match.
  ampSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".config/amp/skills/${name}/SKILL.md" { source = path; }
  ) skills.ampSkills;

  ampSkillScriptFiles = lib.mapAttrs' (
    relPath: src:
    lib.nameValuePair ".config/amp/skills/${relPath}" {
      source = src;
      executable = true;
    }
  ) skills.skillExtraFiles;

  ampSpecutilSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".config/amp/skills/${name}/SKILL.md" { source = path; }
  ) inputs.specutil.lib.skills;

  # devin reads ~/.config/devin/skills/ but was receiving nothing. It gets the
  # Amp render rather than the Claude one: that render carries only frontmatter
  # keys in the common subset (no `model`/`effort`), which is the safe choice
  # for a loader whose validation strictness is not documented.
  devinSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".config/devin/skills/${name}/SKILL.md" { source = path; }
  ) skills.ampSkills;

  devinSkillScriptFiles = lib.mapAttrs' (
    relPath: src:
    lib.nameValuePair ".config/devin/skills/${relPath}" {
      source = src;
      executable = true;
    }
  ) skills.skillExtraFiles;

  devinSpecutilSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".config/devin/skills/${name}/SKILL.md" { source = path; }
  ) inputs.specutil.lib.skills;

  # copilot reads personal skills from ~/.copilot/skills/ (its app bundle names
  # that path, and ~/.agents/skills/, as the personal roots). It gets the Amp
  # render for the same reason devin does: that render carries only frontmatter
  # keys in the common subset, which is the safe choice for a loader whose
  # validation strictness is not documented.
  copilotSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".copilot/skills/${name}/SKILL.md" { source = path; }
  ) skills.ampSkills;

  copilotSkillScriptFiles = lib.mapAttrs' (
    relPath: src:
    lib.nameValuePair ".copilot/skills/${relPath}" {
      source = src;
      executable = true;
    }
  ) skills.skillExtraFiles;

  copilotSpecutilSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".copilot/skills/${name}/SKILL.md" { source = path; }
  ) inputs.specutil.lib.skills;

  # programs.mcp serializes `servers` straight to JSON, so strip option
  # defaults that don't belong on the wire (null command for http servers,
  # null url for stdio servers, the synthetic `type = "local"`, empty
  # headers).
  pruneServer =
    server:
    let
      isHttp = server.type == "http";
      stripped = removeAttrs server [ "type" ];
      filtered = lib.filterAttrs (
        name: value:
        value != null && !(name == "headers" && value == { }) && !(name == "args" && value == [ ])
      ) stripped;
    in
    if isHttp then filtered // { type = "http"; } else filtered;

  mcpServers = lib.mapAttrs (_: pruneServer) config.sysinit.llm.mcp.additionalServers;

  # Every harness config this module imports, by name. Compared against
  # `harnessCoverage` below, because the renderer's own throw only fires for a
  # harness that CALLS the renderer: one that ships a config and no context
  # would pass silently, which is the exact gap the coverage set exists to
  # close. `acp` and `mcp-servers` are not harnesses and are excluded.
  harnessConfigNames = [
    "amp"
    "claude"
    "codex"
    "copilot"
    "crush"
    "cursor"
    "devin"
    "gemini"
    "goose"
    "opencode"
    "pi"
  ];

  llmLibForCoverage = import ./lib { inherit lib; };
  declaredHarnesses = builtins.attrNames llmLibForCoverage.instructions.harnessCoverage;

  undeclaredHarnesses = lib.subtractLists declaredHarnesses harnessConfigNames;
  phantomHarnesses = lib.subtractLists harnessConfigNames declaredHarnesses;

  assertHarnessCoverage =
    if undeclaredHarnesses != [ ] then
      throw "llm/default.nix: ${lib.concatStringsSep ", " undeclaredHarnesses} has a harness config but no harnessCoverage entry. Declare its confirmed context path in lib/instructions.nix."
    else if phantomHarnesses != [ ] then
      throw "llm/default.nix: ${lib.concatStringsSep ", " phantomHarnesses} is declared in harnessCoverage but has no harness config. Remove the stale entry."
    else
      true;

  # Agent-agnostic desktop notifier. The script + per-agent icons are installed
  # once here (multiple harness configs reference notify.exe in their hooks, but
  # only one place may own the home.file/home.packages entries).
  notify = import ./config/notify.nix { inherit pkgs lib; };
in
{
  imports = [
    ./openspec-schema.nix
    ./citation-tools
    ./config/acp.nix
    ./config/amp.nix
    ./config/claude.nix
    ./config/codex.nix
    ./config/copilot-cli.nix
    ./config/crush.nix
    ./config/cursor.nix
    ./config/devin.nix
    ./config/gemini.nix
    ./config/goose.nix
    ./config/mcp-servers.nix
    ./config/opencode.nix
    ./config/pi.nix
  ];

  home.file =
    assert assertHarnessCoverage;
    skillFiles
    // skillScriptFiles
    // specutilSkillFiles
    // (vendoredSkillFilesFor ".claude/skills")
    // ampSkillFiles
    // ampSkillScriptFiles
    // ampSpecutilSkillFiles
    // (vendoredSkillFilesFor ".config/amp/skills")
    // devinSkillFiles
    // devinSkillScriptFiles
    // devinSpecutilSkillFiles
    // (vendoredSkillFilesFor ".config/devin/skills")
    // copilotSkillFiles
    // copilotSkillScriptFiles
    // copilotSpecutilSkillFiles
    // (vendoredSkillFilesFor ".copilot/skills")
    // notify.iconFiles;

  home.packages = [
    notify.script
    notify.stateScript
    notify.promptScript
    notify.focusScript
    notify.reviewScript
    notify.syGate
  ];

  programs.mcp = {
    enable = true;
    servers = mcpServers;
  };
}
