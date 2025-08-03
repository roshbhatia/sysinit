{
  values,
  ...
}:
{
  launchd.user.agents.mcp-hub = {
    command = "mcp-hub --port 43210 --config /Users/${values.user.username}/.config/mcphub/servers.json";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/mcphub.out.log";
      StandardErrorPath = "/tmp/mcphub.err.log";
    };
    environment = {
      PATH = "/usr/bin:/etc/profiles/per-user/${values.user.username}/bin:/Users/${values.user.username}/.local/share/.npm-packages/bin";
    };
  };

}
