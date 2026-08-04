{ lib }:
{
  # Every harness in this repo that speaks the Agent Client Protocol, as the
  # stdio command an ACP client has to spawn. Two shapes exist: a harness with a
  # built-in ACP mode (copilot, devin, goose, opencode) and a harness that needs
  # a separate adapter binary (claude, codex, pi).
  #
  # Commands are bare names, not store paths, because pi-acp is a derivation
  # local to harnesses/pi/default.nix and devin-cli is only on the home profile PATH.
  # Every entry is installed by this repo, so PATH resolution is enough and
  # keeps the registry plain data.
  #
  # amp, crush, and cursor-agent ship no ACP mode at their pinned versions, so
  # they are absent rather than present as broken entries. gemini-cli speaks ACP
  # behind `--experimental-acp`, but this repo does not install that binary.
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

  # Zed-style `agent_servers` shape, which every current ACP client copies.
  formatAsAgentServers = builtins.mapAttrs (
    _name: server:
    {
      inherit (server) command args;
    }
    // lib.optionalAttrs (server.env or { } != { }) { inherit (server) env; }
  );
}
