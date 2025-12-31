_: {
  xdg.configFile = {
    "github-copilot/cli/config.json".text = builtins.toJSON {
      banner = "never";
      render_markdown = true;
      screen_reader = false;
      theme = "auto";
      trusted_folders = [ ];
    };

    "github-copilot/cli/mcp-config.json".text = { };
  };
}
