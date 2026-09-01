{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  skills = import ./skills/render.nix { inherit pkgs; };

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

  # One shape for three roots. This was nine bindings over 47 lines, all reading
  # the same three sources, and a new root meant a fourth copy.
  skillFilesFor =
    root:
    lib.mapAttrs' (
      name: path: lib.nameValuePair "${root}/${name}/SKILL.md" { source = path; }
    ) skills.ampSkills
    // lib.mapAttrs' (
      relPath: src:
      lib.nameValuePair "${root}/${relPath}" {
        source = src;
        executable = true;
      }
    ) skills.skillExtraFiles
    // vendoredSkillFilesFor root;

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

  mcpServers = lib.mapAttrs (_: pruneServer) (
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

  notify = import ./runtime { inherit pkgs lib; };
in
{
  imports = [
    ./skill-tools.nix
    ./acp.nix
    ./harnesses/publish.nix
    ./mcp-servers.nix
    ./harnesses
  ];

  xdg.dataFile = openspecSchemaFiles;

  home = {
    file =
      skillFiles
      // skillScriptFiles
      // openspecSkillFiles
      // openspecCommandFiles
      // (vendoredSkillFilesFor ".claude/skills")
      // lib.mergeAttrsList (
        map skillFilesFor [
          ".config/amp/skills"
          ".config/devin/skills"
          ".copilot/skills"
        ]
      )
      // notify.iconFiles;

    activation.llmManagedFiles = lib.mkIf (config.sysinit.llm.managedFiles != { }) (
      lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${lib.getExe reconciler} || \
          echo "managed-file: one or more harness configs were left untouched; see above. Activation continued." >&2
      ''
    );

    packages = [
      pkgs.meat
      pkgs.sysinit-utils
      capture
      notify.script
      notify.agentRefine
      notify.specPreflight
      notify.promptScript
      notify.focusScript
      notify.reviewScript
      notify.sessionsScript
      notify.syGate
    ];
  };

  programs.mcp = {
    enable = true;
    servers = mcpServers;
  };
}
