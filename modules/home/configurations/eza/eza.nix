{
  lib,
  ...
}:

{
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;

    git = true;
    icons = "auto";
    colors = "auto";

    extraOptions = [
      "--group-directories-first"
      "--header"
      "--time-style=long-iso"
      "--classify"
    ];
  };

  home.shellAliases = lib.mkMerge [
    {
      l = "eza --icons=always -1";
      la = "eza --icons=always -1 -a";
      ll = "eza --icons=always -l -a";
      lt = "eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'";
      tree = "eza --tree --icons=always";
    }
  ];
}
