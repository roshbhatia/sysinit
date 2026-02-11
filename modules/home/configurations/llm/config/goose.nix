{
  lib,
  values,
  ...
}:
let
  skills = import ../skills.nix {
    inherit lib;
    pkgs = null;
  };
  instructions = (import ../instructions.nix).makeInstructions {
    inherit (skills) localSkillDescriptions remoteSkillDescriptions;
  };
  mcp = import ../mcp.nix { inherit lib values; };
  subagents = import ../subagents;

  gooseBuiltinExtensions = {
    autovisualiser = {
      available_tools = [ ];
      bundled = true;
      description = null;
      display_name = "Auto Visualiser";
      enabled = true;
      name = "autovisualiser";
      timeout = 300;
      type = "builtin";
    };
    computercontroller = {
      available_tools = [
        "browser_action"
        "computer_use"
      ];
      bundled = true;
      display_name = "Computer Controller";
      enabled = true;
      name = "computercontroller";
      timeout = 300;
      type = "builtin";
    };
    developer = {
      available_tools = [
        "text_editor"
        "shell"
        "analyze"
        "screen_capture"
        "image_processor"
      ];
      bundled = true;
      display_name = "Developer";
      enabled = true;
      name = "developer";
      timeout = 300;
      type = "builtin";
    };
  };

  gooseHintsMd = instructions;

  capitalizeFirst =
    str:
    let
      firstChar = builtins.substring 0 1 str;
      rest = builtins.substring 1 (-1) str;
    in
    (lib.strings.toUpper firstChar) + rest;

  formatSubagentAsGooseRecipe =
    {
      name,
      config,
    }:
    let
      title = capitalizeFirst name;
      description = config.description or "";
      content = config.instructions or config.description or "";
      triggers = builtins.concatStringsSep "\n" (map (t: "- ${t}") (config.useWhen or [ ]));
      avoid = builtins.concatStringsSep "\n" (map (t: "- ${t}") (config.avoidWhen or [ ]));
      tools = config.tools or { };
      formatTool =
        toolName: if builtins.hasAttr toolName tools then toString tools.${toolName} else "true";
    in
    ''
      title: ${title}
      description: ${description}
      prompt: |
        ${content}

        ${
          if config.triggers or [ ] != [ ] then
            ''
              Key triggers:
              ${builtins.concatStringsSep "\n" (map (t: "  - ${t.trigger or t}") (config.triggers or [ ]))}
            ''
          else
            ""
        }
        ${
          if config.useWhen or [ ] != [ ] then
            ''
              Use when:
              ${triggers}
            ''
          else
            ""
        }
        ${
          if config.avoidWhen or [ ] != [ ] then
            ''
              Avoid when:
              ${avoid}
            ''
          else
            ""
        }
        ${
          if config.category or "" != "" then
            ''
              Category: ${config.category}
            ''
          else
            ""
        }
        ${
          if config.temperature or 0.1 != 0.1 then
            ''
              Temperature: ${toString config.temperature}
            ''
          else
            ""
        }
        Tools: write=${formatTool "write"}, edit=${formatTool "edit"}, background_task=${formatTool "background_task"}
    '';

  formatMcpForGoose =
    mcp:
    builtins.mapAttrs (_name: server: {
      inherit (server) args;
      bundled = null;
      cmd = server.command;
      description = server.description or "";
      enabled = server.enabled or true;
      env_keys = [ ];
      envs = server.env or { };
      name =
        capitalizeFirst (builtins.substring 0 1 _name)
        + builtins.substring 1 (builtins.stringLength _name) _name;
      timeout = 300;
      type = "stdio";
    }) mcp;

  formatPermissionsForGoose = _perms: {
    shell = {
      allow = map (cmd: builtins.replaceStrings [ "*" ] [ ".*" ] cmd) mcp.allPermissions;
      deny = [ ];
    };
  };

  gooseConfig = builtins.toJSON {
    ALPHA_FEATURES = true;
    EDIT_MODE = "vi";
    GOOSE_CLI_THEME = "ansi";
    GOOSE_MODE = "smart_approve";
    GOOSE_RECIPE_GITHUB_REPO = "packit/ai-workflows";
    extensions = gooseBuiltinExtensions // formatMcpForGoose mcp.servers;
    shell = formatPermissionsForGoose mcp.allPermissions;
  };

  subagentRecipeLinksGoose =
    let
      subagentNames = builtins.attrNames (removeAttrs subagents [ "formatSubagentAsMarkdown" ]);
    in
    lib.listToAttrs (
      map (
        name:
        lib.nameValuePair "goose/recipes/${name}.yaml" {
          text = formatSubagentAsGooseRecipe {
            inherit name;
            config = subagents.${name};
          };
        }
      ) subagentNames
    );

  skillRecipesGoose =
    let
      localSkills = builtins.attrNames skills.localSkillDescriptions;
    in
    lib.listToAttrs (
      map (
        name:
        lib.nameValuePair "goose/recipes/${name}.yaml" {
          text = ''
            title: ${capitalizeFirst name}
            description: ${skills.localSkillDescriptions.${name}}
            prompt: |
              Read the skill file at ~/.agents/skills/${name}/SKILL.md for full workflow details.

              ${skills.localSkillDescriptions.${name}}
          '';
        }
      ) localSkills
    );

in
{
  xdg.configFile = lib.mkMerge [
    {
      "goose/config.yaml" = {
        text = gooseConfig;
        force = true;
      };
      "goose/goosehints.md".text = gooseHintsMd;
    }
    subagentRecipeLinksGoose
    skillRecipesGoose
  ];
}
