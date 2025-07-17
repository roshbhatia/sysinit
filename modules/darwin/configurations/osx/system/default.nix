{
  username,
  ...
}:
{
  system = {
    primaryUser = username;
    stateVersion = 4;
  };

  launchd.user.agents.mcp-hub = {
    command = "/Users/${username}/.local/share/.npm-packages/bin/mcp-hub --port 43210 --config /Users/${username}/.config/mcphub/servers.json";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/mcphub.out.log";
      StandardErrorPath = "/tmp/mcphub.err.log";
    };
    environment = {
      PATH = "/usr/bin:/etc/profiles/per-user/${username}/bin";
    };
  };
}
