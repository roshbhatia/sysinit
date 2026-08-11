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

  # `~/.copilot/config.json` is deliberately not managed here, and a `retire`
  # entry for it does not work. Copilot writes the file with a `//` header
  # ("User settings belong in settings.json. This file is managed
  # automatically."), which is JSONC, and the reconcile parses with jq: it
  # reported "cannot parse .copilot/config.json as json" and skipped the file.
  # Teaching the reconcile JSONC would also mean rewriting the file without those
  # comments, which contradicts the header.
  #
  # Nothing is lost. Copilot's own 1.0.35 migration moves the settings keys out of
  # config.json into settings.json on startup and logs the count, so the keys this
  # repository used to declare there are already gone.

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
