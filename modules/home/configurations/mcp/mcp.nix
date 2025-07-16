{
  config,
  ...
}:

{
  launchd.user.agents.mcp-hub = {
    enable = true;
    program = "${config.home.homeDirectory}/.local/share/.npm-packages/bin/mcp-hub";
    programArguments = [
      "${config.home.homeDirectory}/.local/share/.npm-packages/bin/mcp-hub"
      "--port"
      "43210"
    ];
    runAtLoad = true;
    keepAlive = true;
    standardOutPath = "/tmp/mcp-hub.log";
    standardErrorPath = "/tmp/mcp-hub.err";
  };

  xdg.configFile."mcphub/servers.json" = {
    source = ./mcphub.json;
    force = true;
  };

  xdg.configFile."goose/config.yaml" = {
    source = ./goose.yaml;
    force = true;
  };

  xdg.configFile."goose/.goosehints" = {
    source = ./goosehints.md;
    force = true;
  };

  xdg.configFile."opencode/.opencode.json" = {
    source = ./opencode.json;
    force = true;
  };
}

