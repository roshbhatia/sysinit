{ lib }:
{
  servers = {

    amp = {
      command = "acp-amp";
      args = [
        "run"
        "--driver"
        "python"
      ];
    };

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

    cursor = {
      command = "cursor-agent";
      args = [ "acp" ];
    };

    devin = {
      command = "devin";
      args = [ "acp" ];
    };

    goose = {
      command = "goose";
      args = [ "acp" ];
    };

    hermes = {
      command = "hermes-acp";
      args = [ ];
    };

    opencode = {
      command = "opencode";
      args = [ "acp" ];
    };

    pi = {
      command = "pi-acp";
      args = [ ];
    };

    strands = {
      command = "strands";
      args = [ "--acp-server" ];
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
