{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  skills = import ./skills/render.nix { inherit pkgs; };

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
  # tree. harnesses/amp.nix turns off Amp's .claude/skills auto-load to match.
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

  # `suppressedServers` is applied here, after the merge, so a host that reaches a
  # server through a gateway drops the direct entry without editing the shared
  # catalog. A name that matches nothing is a typo that would silently keep the
  # duplicate registration, so it throws.
  suppressed = config.sysinit.llm.mcp.suppressedServers;
  unknownSuppressed = lib.subtractLists (builtins.attrNames config.sysinit.llm.mcp.additionalServers) suppressed;
  assertSuppressedExist =
    if unknownSuppressed != [ ] then
      throw "llm: sysinit.llm.mcp.suppressedServers names ${lib.concatStringsSep ", " unknownSuppressed}, which is not in additionalServers."
    else
      true;

  mcpServers =
    assert assertSuppressedExist;
    lib.mapAttrs (_: pruneServer) (
      lib.filterAttrs (name: _: !(builtins.elem name suppressed)) config.sysinit.llm.mcp.additionalServers
    );

  # Every harness config this module imports, by name. Compared against
  # `harnessCoverage` below, because the renderer's own throw only fires for a
  # harness that CALLS the renderer: one that ships a config and no context
  # would pass silently, which is the exact gap the coverage set exists to
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

  # Config files that both Nix and a harness write. One reconciler runs them
  # all, so the five hand-written merge scripts this replaces cannot drift.
  # Built from the unfiltered set: a disabled entry still needs its recorded
  # base dropped, so the reconciler has to see it.
  reconciler = llmLibForCoverage.managedFile.mkReconciler {
    inherit pkgs;
    files = config.sysinit.llm.managedFiles;
  };

  # Turns a setting changed from inside a harness back into Nix source. The
  # sidecar base makes this a diff rather than a guess: it records exactly what
  # Nix applied, so anything the live file says differently is the owner's.
  capture = llmLibForCoverage.managedFile.mkCapture {
    inherit pkgs;
    files = config.sysinit.llm.managedFiles;
  };

  # Home Manager would install a read-only store symlink over the writable
  # file, so the harness fails to write exactly as it did before. Catch the
  # double declaration at evaluation time rather than at the next save.
  # Compare against `.target`, not the attribute name. home.file keys are not
  # normalized: everything from programs.claude-code and everything routed
  # through xdg.configFile is keyed by absolute path, so an attrName comparison
  # silently misses exactly the collisions that matter. `.target` is
  # home-relative for both sources.
  #
  # Computed from the unfiltered set on purpose. If `enable = false` also
  # switched off the guard, disabling a file would let Home Manager re-link a
  # read-only symlink over the owner's writable copy at the next activation.
  linkedTargets = map (v: v.target) (
    builtins.filter (v: v.enable) (
      builtins.attrValues config.home.file ++ builtins.attrValues config.xdg.configFile
    )
  );
  managedPaths = lib.mapAttrsToList (_: f: f.path) config.sysinit.llm.managedFiles;
  collidingPaths = lib.filter (p: builtins.elem p linkedTargets) managedPaths;

  # Two entries on one path share one sidecar, so each activation writes the
  # file twice and whichever runs last wins. The loser's declaration never
  # reaches disk, silently.
  duplicatePaths = lib.unique (lib.filter (p: lib.count (q: q == p) managedPaths > 1) managedPaths);

  # Agent-agnostic desktop notifier. The script + per-agent icons are installed
  # once here (multiple harness configs reference notify.exe in their hooks, but
  # only one place may own the home.file/home.packages entries).
  notify = import ./runtime { inherit pkgs lib; };
in
{
  imports = [
    ./skill-tools.nix
    ./acp.nix
    ./mcp-servers.nix
    ./harnesses
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

  assertions = [
    {
      assertion = collidingPaths == [ ];
      message = "llm: ${lib.concatStringsSep ", " collidingPaths} is declared in sysinit.llm.managedFiles and also linked by home.file or xdg.configFile. A managed file must not also be a store symlink.";
    }
    {
      assertion = duplicatePaths == [ ];
      message = "llm: ${lib.concatStringsSep ", " duplicatePaths} is declared by more than one sysinit.llm.managedFiles entry. One path may have only one declaration.";
    }
  ];

  # Deliberately does not fail activation. Home Manager runs the activation
  # script under `set -eu`, so a non-zero exit here would skip every later DAG
  # entry (darwin defaults, launch agents, neovim config). A merge conflict is
  # an expected state for a file with two writers, and it must not cost the
  # owner an unrelated switch. The reconciler leaves the conflicting file
  # untouched and every other file is still reconciled.
  # Ordered BEFORE linkGeneration, not merely after writeBoundary. A target
  # that is still a store symlink from the previous generation gets deleted by
  # linkGeneration's cleanup once it leaves home.file. If the reconciler ran
  # after that, a target it then failed to write would be left absent with
  # nothing to restore it. Running first converts the symlink to a real file,
  # and cleanup refuses to delete a non-symlink.
  #
  # Relying on the DAG rather than on the entry names sorting the right way:
  # `linkGeneration` < `llmManagedFiles` bytewise today, which is an accident,
  # not a guarantee.
  home.activation.llmManagedFiles = lib.mkIf (config.sysinit.llm.managedFiles != { }) (
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${lib.getExe reconciler} || \
        echo "managed-file: one or more harness configs were left untouched; see above. Activation continued." >&2
    ''
  );

  home.packages = [
    # Manual use only: `git diff HEAD | meat` when a diff is too large to read.
    # Deliberately absent from the spec-driven apply loop; overlays/meat.nix says
    # why.
    pkgs.meat
    capture
    notify.script
    notify.stateScript
    notify.promptScript
    notify.focusScript
    notify.loopGate
    notify.reviewScript
    notify.sessionsScript
    notify.syGate
    notify.diffNote
  ];

  programs.mcp = {
    enable = true;
    servers = mcpServers;
  };
}
