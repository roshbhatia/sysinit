{
  lib,
  pkgs,
  values,
  ...
}:
let
  skills = import ../skills.nix {
    inherit lib pkgs;
  };
  instructions = (import ../instructions.nix).makeInstructions {
    inherit (skills) localSkillDescriptions remoteSkillDescriptions;
  };
  mcp = import ../mcp.nix { inherit lib values; };

  gooseBuiltinExtensions = {
    autovisualiser = {
      available_tools = [ ];
      bundled = true;
      description = "";
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
      description = "";
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
      description = "";
      display_name = "Developer";
      enabled = true;
      name = "developer";
      timeout = 300;
      type = "builtin";
    };
  };

  goosePlatformExtensions = {
    skills = {
      available_tools = [ ];
      bundled = true;
      description = "Load and use skills from relevant directories";
      display_name = "Skills";
      enabled = true;
      name = "skills";
      type = "platform";
    };
    extensionmanager = {
      available_tools = [ ];
      bundled = true;
      description = "Enable extension management tools for discovering, enabling, and disabling extensions";
      display_name = "Extension Manager";
      enabled = true;
      name = "Extension Manager";
      type = "platform";
    };
    code_execution = {
      available_tools = [ ];
      bundled = true;
      description = "Goose will make extension calls through code execution, saving tokens";
      display_name = "Code Mode";
      enabled = true;
      name = "code_execution";
      type = "platform";
    };
    apps = {
      available_tools = [ ];
      bundled = true;
      description = "Create and manage custom Goose apps through chat. Apps are HTML/CSS/JavaScript and run in sandboxed windows.";
      display_name = "Apps";
      enabled = true;
      name = "apps";
      type = "platform";
    };
    chatrecall = {
      available_tools = [ ];
      bundled = true;
      description = "Search past conversations and load session summaries for contextual memory";
      display_name = "Chat Recall";
      enabled = true;
      name = "chatrecall";
      type = "platform";
    };
    todo = {
      available_tools = [ ];
      bundled = true;
      description = "Enable a todo list for goose so it can keep track of what it is doing";
      display_name = "Todo";
      enabled = false;
      name = "todo";
      type = "platform";
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
    EDIT_MODE = "vi";
    GOOSE_CLI_MIN_PRIORITY = 0.2;
    GOOSE_CLI_THEME = "ansi";
    GOOSE_MODE = "smart_approve";
    GOOSE_TOOLSHIM = true;

    extensions = gooseBuiltinExtensions // goosePlatformExtensions // formatMcpForGoose mcp.servers;
    shell = formatPermissionsForGoose mcp.allPermissions;
  };

  gooseSkillLinks =
    let
      allSkillNames =
        builtins.attrNames skills.localSkillDescriptions
        ++ builtins.attrNames skills.remoteSkillDescriptions;
    in
    lib.listToAttrs (
      map (
        name:
        lib.nameValuePair ".goose/skills/${name}/SKILL.md" {
          source = skills.allSkills.${name};
        }
      ) allSkillNames
    );

in
{
  home.sessionVariables = {
    CONTEXT_FILE_NAMES = builtins.toJSON [
      "AGENTS.md"
      ".goosehints"
      ".cursorrules"
      "CLAUDE.md"
      "CONSTITUTION.md"
      "CONTRIBUTING.md"
      "COPILOT.md"
    ];
  };

  home.file = gooseSkillLinks;
  xdg.configFile = {
    "goose/config.yaml" = {
      text = gooseConfig;
      force = true;
    };

    # Keep goosehints.md for backwards compatibility
    "goose/goosehints.md".text = gooseHintsMd;
  };
}
