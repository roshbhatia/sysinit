{ inputs, ... }:

{
  imports = [
    inputs.direnv-instant.homeModules.direnv-instant
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableNushellIntegration = true;
      # Disable the integration in zsh so we can use direnv-instant
      enableZshIntegration = false;
    };

    direnv-instant = {
      enable = true;
      enableZshIntegration = true;
      settings.mux_delay = 2;
    };
  };
}
