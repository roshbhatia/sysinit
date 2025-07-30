{
  config,
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  paths = import ../../../lib/paths { inherit config lib; };
  vividTheme = themes.getAppTheme "vivid" values.theme.colorscheme values.theme.variant;
  nushellTheme = themes.getAppTheme "nushell" values.theme.colorscheme values.theme.variant;

  pathsList = paths.getAllPaths config.home.username config.home.homeDirectory;
in
{
  programs.nushell = {
    enable = true;

    configFile.source = ./core/config.nu;
    extraConfig = ''
      $env.LS_COLORS = (vivid generate ${vividTheme})
      $env.EZA_COLORS = $env.LS_COLORS

      source theme.nu

      source wezterm.nu

      source atuin.nu
      source direnv.nu
      source zoxide.nu

      source carapace.nu
      source kubectl.nu

      source macchina.nu
      source omp.nu
    '';

    envFile.source = ./core/env.nu;

    extraEnv = ''
      let paths = [
        ${lib.concatStringsSep "\n        " (map (path: "\"${path}\"") pathsList)}
      ]

      for path in $paths {
        path_add $path
      }
    '';

    plugins = with pkgs.nushellPlugins; [
      highlight
      formats
      polars
    ];

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

      # Required for macos
      nu-open = "open";
      open = "^open";
    };
    environmentVariables = config.home.sessionVariables;
  };

  xdg.configFile = {
    "nushell/theme.nu".source = ./themes/${nushellTheme};
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
