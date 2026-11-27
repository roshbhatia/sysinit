_:

{
  programs.nix-your-shell = {
    enable = true;
    nix-output-monitor.enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };
}
