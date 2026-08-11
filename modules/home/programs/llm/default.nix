{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  skills = import ./skills/render.nix { inherit pkgs; };

  # specutil's agent skills, from the vendored source tree rather than a flake
  # input. The directory is read instead of the names being listed, so adding a
  # skill under pkgs/specutil/skills is one edit rather than two, and a skill
  # directory without a SKILL.md cannot render a broken home.file entry.
  specutilSkillRoot = ../../../../pkgs/specutil/skills;
  specutilSkills = lib.mapAttrs (name: _: specutilSkillRoot + "/${name}/SKILL.md") (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (specutilSkillRoot + "/${name}/SKILL.md")
    ) (builtins.readDir specutilSkillRoot)
  );

  skillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { source = path; }
  ) skills.allSkills;

  skillScriptFiles = lib.mapAttrs' (
    relPath: src:
    lib.nameValuePair ".claude/skills/${relPath}" {
      source = src;
      executable = true;
    }
  ) skills.skillExtraFiles;

  specutilSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { source = path; }
  ) specutilSkills;

  openspecSkills =
    pkgs.runCommand "openspec-skills"
      {
        nativeBuildInputs = [
          pkgs.git
          pkgs.openspec
          pkgs.coreutils
        ];
      }
      ''
        export HOME="$TMPDIR/home"
        export OPENSPEC_TELEMETRY=0
        export CI=true
        mkdir -p "$HOME" work && cd work
        git init -q .
        git config user.email nix@localhost
        git config user.name nix
        timeout 180 openspec init --tools claude --profile core --force < /dev/null > /dev/null

        [ -d .claude/skills ] || { echo "openspec init produced no .claude/skills" >&2; exit 1; }
        [ -d .claude/commands/opsx ] || { echo "openspec init produced no .claude/commands/opsx" >&2; exit 1; }

        mkdir -p $out
        cp -r .claude/skills $out/skills
        cp -r .claude/commands/opsx $out/commands
      '';

  # Linked as directories rather than enumerated. Reading the directory at
  # evaluation time would force `openspecSkills` to build, and a linux home
  # configuration then cannot evaluate on a darwin machine. home-manager links a
  # recursive entry with `lndir` at build time, so the other `.claude/skills`
  # entries still land beside these.
  openspecSkillFiles = {
    ".claude/skills" = {
      source = "${openspecSkills}/skills";
      recursive = true;
    };
  };

  openspecCommandFiles = {
    ".claude/commands/opsx" = {
      source = "${openspecSkills}/commands";
      recursive = true;
    };
  };

  openspecSchemaRoot = ./openspec-schema;
  openspecSchemaFiles = lib.listToAttrs (
    map
      (relPath: {
        name = "openspec/schemas/spec-driven/${relPath}";
        value.source = openspecSchemaRoot + "/${relPath}";
      })
      (
        map (f: lib.removePrefix "${toString openspecSchemaRoot}/" (toString f)) (
          lib.filesystem.listFilesRecursive openspecSchemaRoot
        )
      )
  );

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
  ) specutilSkills;

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
  ) specutilSkills;

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
  ) specutilSkills;

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

  llmLibForCoverage = import ./lib { inherit lib; };

  reconciler = llmLibForCoverage.managedFile.mkReconciler {
    inherit pkgs;
    files = config.sysinit.llm.managedFiles;
  };

  capture = llmLibForCoverage.managedFile.mkCapture {
    inherit pkgs;
    files = config.sysinit.llm.managedFiles;
  };

  linkedTargets = map (v: v.target) (
    builtins.filter (v: v.enable) (
      builtins.attrValues config.home.file ++ builtins.attrValues config.xdg.configFile
    )
  );
  managedPaths = lib.mapAttrsToList (_: f: f.path) config.sysinit.llm.managedFiles;
  collidingPaths = lib.filter (p: builtins.elem p linkedTargets) managedPaths;

  duplicatePaths = lib.unique (lib.filter (p: lib.count (q: q == p) managedPaths > 1) managedPaths);

  notify = import ./runtime { inherit pkgs lib; };
in
{
  imports = [
    ./skill-tools.nix
    ./acp.nix
    ./mcp-servers.nix
    ./harnesses
  ];

  xdg.dataFile = openspecSchemaFiles;

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

  home = {
    file =
      skillFiles
      // skillScriptFiles
      // specutilSkillFiles
      // openspecSkillFiles
      // openspecCommandFiles
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

    activation.llmManagedFiles = lib.mkIf (config.sysinit.llm.managedFiles != { }) (
      lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${lib.getExe reconciler} || \
          echo "managed-file: one or more harness configs were left untouched; see above. Activation continued." >&2
      ''
    );

    packages = [
      pkgs.meat
      # On PATH under its own name, because the skill and the allowlist both
      pkgs.sysinit-agent
      capture
      notify.script
      notify.agentRefine
      notify.specPreflight
      notify.stateScript
      notify.promptScript
      notify.focusScript
      notify.loopGate
      notify.reviewScript
      notify.sessionsScript
      notify.syGate
      notify.noteReview
    ];
  };

  programs.mcp = {
    enable = true;
    servers = mcpServers;
  };
}
