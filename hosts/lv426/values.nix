{
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
}
