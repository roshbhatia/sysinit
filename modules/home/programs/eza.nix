_:

{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;

    git = true;
    icons = "auto";
    colors = "auto";

    extraOptions = [
      "--time-style=long-iso"
    ];
  };
}
