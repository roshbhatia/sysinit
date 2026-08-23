{ lib }:
{
  servers = {
    # Amp ships no ACP mode of its own, so this is the acp-amp bridge, packaged in
    # overlays/acp-amp.nix. `run` is the subcommand that speaks ACP on stdio;
    # without it the bridge prints help and exits.
    #
    # The driver is pinned to python. The default is `auto`, which falls back to a
    # Node shim and a bare `node`, and this bridge is launched by clients that
    # carry no PATH. The python driver answered `initialize` with protocolVersion
    # 1 here, so the fallback buys nothing.
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

    devin = {
      command = "devin";
      args = [ "acp" ];
    };

    goose = {
      command = "goose";
      args = [ "acp" ];
    };

    # `hermes acp` and `hermes-acp` are the same adapter. The dedicated binary is
    # the one overlays/hermes-agent.nix wraps with the subagent PATH, so a
    # spawned helper resolves. It is also slow to answer `initialize`: about ten
    # seconds here, against under one for every other server in this list.
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
  };

  formatAsAgentServers = builtins.mapAttrs (
    _name: server:
    {
      inherit (server) command args;
    }
    // lib.optionalAttrs (server.env or { } != { }) { inherit (server) env; }
  );
}
