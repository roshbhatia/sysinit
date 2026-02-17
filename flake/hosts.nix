common:

{
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;

    profile = "host-minimal";

    sysinit = common.sysinit;

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

  lima-dev = {
    system = "aarch64-linux";
    platform = "linux";
    username = "dev";

    profile = "dev-full";

    sysinit = common.sysinit;

    values = common.values // {
      theme = {
        colorscheme = "everforest";
        variant = "dark-soft";
      };
    };
  };

  lima-minimal = {
    system = "aarch64-linux";
    platform = "linux";
    username = "dev";

    profile = "dev-minimal";

    sysinit = common.sysinit;

    values = common.values // {
      theme = {
        colorscheme = "everforest";
        variant = "dark-soft";
      };
    };
  };
}
