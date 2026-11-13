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
      executable = lib.hasInfix "/scripts/" relPath;
    }
  ) skills.skillExtraFiles;

  astGrepSkillRoot = "${inputs.ast-grep-skills}/ast-grep/skills";
  astGrepSkillFiles = {
    "ast-grep/SKILL.md" = "${astGrepSkillRoot}/ast-grep/SKILL.md";
    "ast-grep/references/rule_reference.md" =
      "${astGrepSkillRoot}/ast-grep/references/rule_reference.md";
    "ast-grep-outline/SKILL.md" = "${astGrepSkillRoot}/outline/SKILL.md";
  };

  vendoredSkillFiles = astGrepSkillFiles // {
    "socratic-tutor/SKILL.md" = "${inputs.janestreet-skills}/socratic-tutor/SKILL.md";
  };

  vendoredSkillFilesFor =
    root:
    lib.mapAttrs' (rel: src: lib.nameValuePair "${root}/${rel}" { source = src; }) vendoredSkillFiles;

  skillFilesFor =
    root:
    lib.mapAttrs' (
      name: path: lib.nameValuePair "${root}/${name}/SKILL.md" { source = path; }
    ) skills.ampSkills
    // lib.mapAttrs' (
      relPath: src:
      lib.nameValuePair "${root}/${relPath}" {
        source = src;
        executable = lib.hasInfix "/scripts/" relPath;
      }
    ) skills.skillExtraFiles
    // vendoredSkillFilesFor root;

  mcpCatalog = import ./lib/mcp-catalog.nix {
    inherit lib;
    inherit (config.sysinit.llm.mcp)
      additionalServers
      suppressedServers
      harnessSuppressedServers
      harnessOverrides
      ;
    routeServer = import ./lib/mcp-routing.nix { inherit lib pkgs; };
  };

  llmLibForCoverage = import ./lib { inherit lib; };

  reconciler = llmLibForCoverage.managedFile.mkReconciler {
    inherit pkgs;
    files = config.sysinit.llm.managedFiles;
  };

  capture = llmLibForCoverage.managedFile.mkCapture {
    inherit pkgs;
    files = config.sysinit.llm.managedFiles;
  };

  notify = import ./runtime {
    inherit pkgs lib;
    notificationSettings = config.sysinit.llm.notifications.settings;
    iconOverrides = config.sysinit.llm.notifications.icons;
    notificationAppPath =
      if pkgs.stdenv.hostPlatform.isDarwin then
        "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/CLI Agents.app"
      else
        null;
  };
in
{
  sysinit.llm.instructions.skillRoutes = lib.mkBefore [
    {
      intent = "Code discovery";
      skills = [ "search-code-routing" ];
    }
    {
      intent = "Design decisions or agreed implementation plans";
      skills = [
        "writing-doc-rfc"
        "writing-doc-design"
      ];
    }
    {
      intent = "Reproduce and fix a defect";
      skills = [ "debugging" ];
    }
    {
      intent = "Plan and verify checks for a change";
      skills = [ "change-validation" ];
    }
    {
      intent = "Commits and pull requests";
      skills = [
        "writing-commit-message"
        "writing-pr-description"
        "gh-stack"
      ];
    }
    {
      intent = "Nix builds, input pins, or activation";
      skills = [ "nix-deployment" ];
    }
  ];

  imports = [
    ./skill-tools.nix
    ./gate.nix
    ./acp.nix
    ./harnesses/publish.nix
    ./mcp-servers.nix
    ./harnesses
  ];

  xdg = {
    dataFile = notify.iconFiles;
    configFile = {
      "agent-notify/config.json".source = notify.configFile;
      "agent-notify/schema.json".source = notify.schema;
      "agent-notify/assets.json".source = notify.assetManifest;
      "sysinit/skills.json".source = pkgs.sysinit.writeJSON "skills-catalog.json" {
        roots = lib.unique (map (h: h.skillRoot) (builtins.attrValues (import ./harnesses/registry.nix)));
        descriptions =
          skills.localSkillDescriptions // config.sysinit.llm.instructions.additionalSkillDescriptions;
        resources = builtins.attrNames skills.skillExtraFiles;
      };
      "sysinit/mcp-clients.json".source = pkgs.sysinit.writeJSON "llm-default.json" (
        lib.genAttrs (builtins.attrNames (import ./harnesses/registry.nix)) mcpCatalog.serversFor
      );
    };
  };

  home = {

    sessionPath =
      llmLibForCoverage.commandPath.homeEntriesFor pkgs.stdenv.hostPlatform.isDarwin
        "${config.home.profileDirectory}/bin"
        config.home.homeDirectory;

    file =
      skillFiles
      // skillScriptFiles
      // (vendoredSkillFilesFor ".claude/skills")
      // lib.mergeAttrsList (
        map skillFilesFor (
          lib.remove ".claude/skills" (
            lib.unique (map (h: h.skillRoot) (builtins.attrValues (import ./harnesses/registry.nix)))
          )
        )
      );

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
      (import ./runtime/diff { inherit pkgs; })
      notify.script
      notify.agentRefine
      notify.promptScript
      notify.focusScript
      notify.reviewScript
      notify.sessionsScript
      pkgs.seshy
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin notify.appPackage;
  };

  programs.mcp = {
    enable = true;
    inherit (mcpCatalog) servers;
  };
}
