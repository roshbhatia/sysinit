{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # `~/.copilot/settings.json`, not `config.json`. Copilot CLI 1.0.35 split the
  # two, in its own words: "User settings are now stored in
  # ~/.copilot/settings.json, separate from internal state in config.json". The
  # CLI migrates settings out of config.json on startup and logs how many it
  # moved, so declaring them there fought the migration once per switch.
  #
  # Every name below is one of the 60 keys in the settings schema the installed
  # 1.0.61 bundle validates against. `copilot help config` documents them.
  copilotSettings = {
    banner = "never";
    renderMarkdown = true;
    screenReader = false;
    theme = "auto";
    autoUpdate = false;
  };

  copilotMcpConfig = builtins.toJSON {
    mcpServers = llmLib.mcp.formatForCopilot kit.mcpServers.servers;
  };
in
{

  sysinit.llm.managedFiles.copilot = {
    path = ".copilot/settings.json";
    format = "json";
    content = copilotSettings;

    # `autoUpdate` alone. The other four are display preferences, and `/settings`
    # is where they belong if the owner changes one. A copilot that updates
    # itself replaces the nix-installed binary with one nothing declares, so this
    # is the enforcement setting rather than a preference.
    enforce = [ "autoUpdate" ];
  };

  # Only to retire keys. `config.json` is copilot's own state file, so nothing
  # here declares content for it.
  sysinit.llm.managedFiles.copilot-config = {
    path = ".copilot/config.json";
    format = "json";
    content = { };
    createIfMissing = false;

    # `trusted_folders` was never a key copilot read: it is absent from the
    # settings schema and from the three legacy aliases the migration honours, so
    # the CLI leaves it in place forever. The five settings keys are retired
    # because this repository declared them here until 1.0.35 moved them, and the
    # merge preserves a key the recorded base does not account for.
    retire = [
      "trusted_folders"
      "banner"
      "renderMarkdown"
      "screenReader"
      "theme"
      "autoUpdate"
    ];
  };
  home.file = {
    ".copilot/mcp-config.json" = {
      text = copilotMcpConfig;
      force = true;
    };

    ".copilot/copilot-instructions.md" = {
      text = kit.mkInstructionsWithStyle {
        harness = "copilot";
        skillsRoot = "~/.copilot/skills";
      };
      force = true;
    };
  };
}
