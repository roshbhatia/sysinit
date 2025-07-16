{
  config,
  username,
  ...
}:
{
  system = {
    primaryUser = username;
    stateVersion = 4;
  };

  launchd.user.agents.mcp-hub = {
    command = "/Users/${username}/.local/share/.npm-packages/bin/mcp-hub --port 43210";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/mcphub.out.log";
      StandardErrorPath = "/tmp/mcphub.err.log";
    };
  };
}
