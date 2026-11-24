{
  pkgs,
  homeConfigurations,
  darwinConfigurations,
  nixosConfigurations,
}:
let
  inherit (pkgs) lib;
  nuCheck = import ../lib/nushell.nix { inherit pkgs; };
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
in
{
  pi = pkgs.pi-coding-agent;

  traces-opencode-runtime =
    assert pkgs.traces-providers.providers.opencode.providerRuntimeInputs == [ pkgs.opencode ];
    nuCheck {
      name = "traces-opencode-runtime";
      script = ../lib/command-contracts.nu;
      sources = [ ../lib/process.nu ];
      arguments = [
        "contains"
        "${pkgs.traces-providers}/bin/traces-provider-opencode"
        "${pkgs.opencode}/bin"
      ];
    };

  conductor = pkgs.conductor-cli;

  codex-daemon = import ./codex-daemon.nix { inherit pkgs; };

  native-output = import ./native-output.nix { inherit pkgs; };

  pi-extensions = import ./pi-extensions.nix { inherit pkgs; };

  pi-types = import ./pi-types.nix { inherit pkgs; };

  strands = pkgs.strands-cli;

  opencode = import ./opencode.nix { inherit pkgs; };

  agent-sessions = import ./agent-sessions.nix { inherit pkgs; };

  mcp-client-routing = import ./mcp-routing.nix { inherit pkgs; };

  managed-file-cache = import ./managed-file-cache.nix { inherit pkgs; };

  mcp-harness-suppression = import ./mcp-harness-suppression.nix { inherit pkgs; };

  skill-catalog = import ./skill-catalog.nix {
    inherit pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
  };

  harness-instructions = import ./harness-instructions.nix {
    inherit pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
    inherit (pkgs) lib;
  };

  codex-config = import ./codex-config.nix {
    inherit pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
    inherit (pkgs) lib;
  };

  egm-plugins = import ./egm-plugins.nix {
    inherit pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
  };

  harness-settings = import ./harness-settings.nix {
    inherit pkgs darwinConfigurations nixosConfigurations;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
  };

  gate-config = import ./gate-config.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };

  llm-composition = import ./llm-composition.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  codex-mcp-capabilities = nativeCheck {
    name = "codex-mcp-capabilities";
    inputs = [ pkgs.python3 ];
    commands = [
      [
        "python3"
        ./codex-mcp-capabilities.py
        (lib.getExe pkgs.codex)
      ]
    ];
  };
}
