common:

{
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;
    values = common.values // {
      darwin.homebrew.additionalPackages.casks = [
        "betterdiscord-installer"
        "calibre"
        "discord"
        "steam"
      ];
      theme = {
        colorscheme = "kanagawa";
        variant = "lotus";
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

  arrakis = {
    system = "x86_64-linux";
    platform = "linux";
    inherit (common) username;
    values = common.values // {
      theme = {
        colorscheme = "gruvbox";
        variant = "dark";
        font = {
          monospace = "MonaspiceKr Nerd Font Mono";
        };
      };
    };
  };
}
