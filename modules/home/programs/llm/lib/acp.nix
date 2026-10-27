{ lib }:
let
  servers = {

    amp = {
      command = "acp-amp";
      args = [
        "run"
        "--driver"
        "python"
      ];
      gooseProvider = {
        name = "amp-acp";
        model = "current";
      };
    };

    claude = {
      command = "claude-agent-acp";
      args = [ ];
      gooseProvider = {
        name = "claude-acp";
        model = "default";
      };
    };

    codex = {
      command = "codex-acp";
      args = [ ];
      gooseProvider = {
        name = "codex-acp";
        model = "current";
      };
    };

    copilot = {
      command = "copilot";
      args = [ "--acp" ];
      gooseProvider = {
        name = "copilot-acp";
        model = "current";
      };
    };

    cursor = {
      command = "cursor-agent";
      args = [ "acp" ];
      gooseProvider = {
        name = "cursor-agent";
        model = "auto";
      };
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
      gooseProvider = {
        name = "pi-acp";
        model = "current";
      };
    };

    strands = {
      command = "strands";
      args = [ "--acp-server" ];
    };
  };
in
{
  inherit servers;

  gooseProviders = lib.mapAttrs' (
    _name: server:
    lib.nameValuePair server.gooseProvider.name {
      inherit (server.gooseProvider) model;
      configured = true;
      enabled = true;
    }
  ) (lib.filterAttrs (_name: server: server ? gooseProvider) servers);

  formatAsAgentServers = builtins.mapAttrs (
    _name: server:
    {
      inherit (server) command args;
    }
    // lib.optionalAttrs (server.env or { } != { }) { inherit (server) env; }
  );
}
