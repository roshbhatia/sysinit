_:

{
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

    git = true;
    icons = "auto";
    colors = "auto";

    extraOptions = [
      "--time-style=long-iso"
    ];
  };
}
