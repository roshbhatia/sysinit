{ ... }:

{
  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    direnv-instant = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
