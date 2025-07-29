{
  config,
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  appTheme = themes.getAppTheme "vivid" values.theme.colorscheme values.theme.variant;
in
{

  programs.carapace.enableNushellIntegration = true;
  programs.nushell = {
    enable = true;

    configFile.source = ./core/config.nu;
    envFile.source = ./core/env.nu;

    shellAliases = {
      "....." = "cd ../../../..";
      "...." = "cd ../../..";
      "..." = "cd ../..";
      ".." = "cd ..";
      "~" = "cd ~";
      code = "code-insiders";
      c = "code-insiders";
      kubectl = "kubecolor";
      l = "ls";
      la = "ls -a";
      ll = "ls -la";
      lt = "eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'";
      tf = "terraform";
      y = "yazi";
      v = "nvim";
      g = "git";
      sudo = "sudo -E";
      diff = "diff --color";
      grep = "grep -s --color=auto";
      watch = "watch --quiet";
    };

    environmentVariables = config.home.sessionVariables;

    extraConfig = ''
      $env.LS_COLORS = (vivid generate ${appTheme})
      $env.EZA_COLORS = $env.LS_COLORS

      source wezterm.nu

      source atuin.nu
      source direnv.nu
      source zoxide.nu

      source carapace.nu
      source kubectl.nu

      source macchina.nu
      source omp.nu
    '';
  };

  xdg.configFile = {
    "nushell/atuin.nu".source = ./core/atuin.nu;
    "nushell/carapace.nu".source = ./core/carapace.nu;
    "nushell/direnv.nu".source = ./core/direnv.nu;
    "nushell/kubectl.nu".source = ./core/kubectl.nu;
    "nushell/macchina.nu".source = ./core/macchina.nu;
    "nushell/omp.nu".source = ./core/omp.nu;
    "nushell/wezterm.nu".source = ./core/wezterm.nu;
    "nushell/zoxide.nu".source = ./core/zoxide.nu;
  };
}

