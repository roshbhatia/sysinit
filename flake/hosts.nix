common:

{
  # macOS host - use minimal profile
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;

    # Reference profile instead of inline configuration
    profile = "host-minimal";

    # Sysinit namespace values (from common.sysinit)
    sysinit = common.sysinit;

    # Host-specific overrides
    values = common.values // {
      darwin.homebrew.additionalPackages.casks = [
        "betterdiscord-installer"
        "discord"
        "ghostty"
        "steam"
      ];
      theme = {
        colorscheme = "everforest";
        variant = "dark-soft";
      };
      llm.mcp.additionalServers = {
        playwright = {
          command = "npx";
          args = [
            "playwriter@latest"
          ];
          description = "A Model Context Protocol (MCP) server that provides browser automation capabilities using Playwright. This server enables LLMs to interact with web pages through structured accessibility snapshots, bypassing the need for screenshots or visually-tuned models.";
        };
      };
    };
  };

  # Lima dev VM - full development environment (stub for PRD-03)
  lima-dev = {
    system = "aarch64-linux";
    platform = "linux";
    username = "dev";

    profile = "dev-full";

    # Sysinit namespace values (from common.sysinit)
    sysinit = common.sysinit;

    values = common.values // {
      theme = {
        colorscheme = "everforest";
        variant = "dark-soft";
      };
    };
  };

  # Lima minimal VM - basic dev tools only (stub for PRD-03)
  lima-minimal = {
    system = "aarch64-linux";
    platform = "linux";
    username = "dev";

    profile = "dev-minimal";

    # Sysinit namespace values (from common.sysinit)
    sysinit = common.sysinit;

    values = common.values // {
      theme = {
        colorscheme = "everforest";
        variant = "dark-soft";
      };
    };
  };
}
