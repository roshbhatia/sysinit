{ lib, values, pkgs, ... }:
let
  cfg = values.llm.execution;
  enabled = cfg.enabled or true;
in
{
  imports = [
    ./config/claude.nix
    ./config/cursor-agent.nix
    ./config/goose.nix
    ./config/opencode.nix
  ];

  config = lib.mkIf enabled {
    # Nix-shell integration for dynamic dependency management
    home.packages = with pkgs; [
      nix-your-shell
      nix-output-monitor
    ];

    # Shell integration for nix-shell
    programs.zsh.shellAliases = {
      nix-shell-deps = "nix-shell -p";
      nix-run = "nix run";
      nix-exec = "nix-shell --run";
    };

    # Environment variables for execution
    home.sessionVariables = {
      NIX_SHELL_PROMPT = "llm-env";
      NIX_BUILD_SHELL = "${pkgs.zsh}/bin/zsh";
    };
  };
}