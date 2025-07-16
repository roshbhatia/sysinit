{ config, username, ... }:
{
  system = {
    primaryUser = username;
    stateVersion = 4;
  };

  launchd.user.agents.mcp-hub = {
    enable = true;
    program = "/Users/${username}/.local/share/.npm-packages/bin/mcp-hub";
    programArguments = [
      "${config.home.homeDirectory}/.local/share/.npm-packages/bin/mcp-hub"
      "--port"
      "43210"
    ];
    runAtLoad = true;
    keepAlive = true;
  };
}

