{
  pkgs,
  homeConfigurations,
  darwinConfigurations,
  nixosConfigurations,
  nuFunctions,
}:
let
  inherit (pkgs) lib;
  nuCheck = import ../lib/nushell.nix { inherit pkgs; };
in
{
  zsh-agent-shell = nuCheck {
    name = "zsh-agent-shell";
    script = ./zsh-agent-shell.nu;
    arguments = [
      (lib.getExe pkgs.zsh)
      ../../modules/home/programs/zsh/core/agent-glob.zsh
    ];
    inputs = [ pkgs.zsh ];
  };

  nushell-utilities = import ./nushell-utilities.nix { inherit pkgs; };

  shell-completions = import ./shell-completions.nix { inherit pkgs; };

  completion-cache =
    pkgs.runCommand "completion-cache-test"
      {
        nativeBuildInputs = [
          pkgs.nushell
          pkgs.zsh
          pkgs.coreutils
        ];
      }
      ''
        nu --no-config-file ${./completion-cache.nu} ${../../modules/home/programs/zsh/core/compinit.zsh}
        touch "$out"
      '';

  atuin = import ./atuin.nix {
    inherit lib pkgs;
    home = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config;
  };

  nushell-managed-tools = import ./nushell-managed-tools.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };

  nushell-completions = import ./nushell-completions.nix {
    inherit pkgs;
    inherit (pkgs) lib;
    fzf = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.config.programs.fzf.package;
  };

  nushell-externs = import ./nushell-externs.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };

  wezterm-shell = import ./wezterm-shell.nix {
    inherit pkgs darwinConfigurations nixosConfigurations;
  };

  nushell-wezterm = import ./nushell-wezterm.nix { inherit pkgs homeConfigurations nuFunctions; };

  nushell-plugin-registration = nuCheck {
    name = "nushell-plugin-registration";
    script = ../lib/command-contracts.nu;
    sources = [ ../lib/process.nu ];
    arguments = [
      "plugins"
      (lib.getExe pkgs.nu-plugin-nuvim)
    ];
  };

  nushell-command-surface = nuCheck {
    name = "nushell-command-surface";
    script = ../lib/command-contracts.nu;
    sources = [ ../lib/process.nu ];
    arguments = [
      "command-surface"
      nuFunctions
    ];
  };
}
