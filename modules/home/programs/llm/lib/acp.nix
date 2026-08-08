{ lib }:
{
  servers = {
    claude = {
      command = "claude-agent-acp";
      args = [ ];
    };

    codex = {
      command = "codex-acp";
      args = [ ];
    };

    copilot = {
      command = "copilot";
      args = [ "--acp" ];
    };

    devin = {
      command = "devin";
      args = [ "acp" ];
    };

    goose = {
      command = "goose";
      args = [ "acp" ];
    };

    opencode = {
      command = "opencode";
      args = [ "acp" ];
    };

    pi = {
      command = "pi-acp";
      args = [ ];
    };
  };

  formatAsAgentServers = builtins.mapAttrs (
    _name: server:
    {
      inherit (server) command args;
    }
    // lib.optionalAttrs (server.env or { } != { }) { inherit (server) env; }
  );
}
