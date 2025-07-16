{ username, ... }:
{
  system = {
    primaryUser = username;
    stateVersion = 4;
  };

  launchd.user.agents.mcp-hub = {
    enable = true;
    program = "/Users/rbha18/.local/share/.npm-packages/bin/mcp-hub";
    programArguments = [
      "/Users/rbha18/.local/share/.npm-packages/bin/mcp-hub"
      "--port"
      "3210"
    ];
    runAtLoad = true;
    keepAlive = true;
    standardOutPath = "/tmp/mcp-hub.log";
    standardErrorPath = "/tmp/mcp-hub.err";
  };
}
