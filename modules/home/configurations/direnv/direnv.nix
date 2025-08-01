{
  ...
}:

{
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = false;
      nix-direnv.enable = true;
    };
  };
}
