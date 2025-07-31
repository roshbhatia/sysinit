{
  username,
  ...
}:
{
  launchd.user.agents.mcp-hub = {
    command = "mcp-hub --port 43210 --config /Users/${username}/.config/mcphub/servers.json";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/mcphub.out.log";
      StandardErrorPath = "/tmp/mcphub.err.log";
    };
    environment = {
      PATH = "/usr/bin:/etc/profiles/per-user/${username}/bin:/Users/${username}/.local/share/.npm-packages/bin";
    };
  };

  launchd.user.agents.litellm = {
    command = "litellm --config /Users/${username}/.config/litellm/config.yaml --port 43211";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/litellm.out.log";
      StandardErrorPath = "/tmp/litellm.err.log";
    };
    environment = {
      PATH = "/usr/bin:/etc/profiles/per-user/${username}/bin";
      OPENAI_API_KEY = "sk-test-1234567890abcdef1234567890abcdef";
    };
  };
}

