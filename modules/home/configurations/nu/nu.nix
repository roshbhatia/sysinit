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

  # Core nushell configuration
  coreModules = [
    "theme.nu"
    "wezterm.nu"
    "atuin.nu"
    "direnv.nu"
    "zoxide.nu"
    "carapace.nu"
    "kubectl.nu"
    "macchina.nu"
    "omp.nu"
  ];

  # Generate source statements for core modules
  moduleSourceStatements = lib.concatStringsSep "\n      " (
    map (module: "source ${module}") coreModules
  );
in
{
  programs.nushell = {
    enable = true;

    configFile.source = ./core/config.nu;
    envFile.source = ./core/env.nu;

    extraConfig = ''
      # Environment setup
      $env.LS_COLORS = (vivid generate ${vividTheme})
      $env.EZA_COLORS = $env.LS_COLORS

      # Load core modules
      ${moduleSourceStatements}
    '';

    extraEnv = ''
      # Dynamic path configuration
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
      # Navigation shortcuts
      "....." = "cd ../../../..";
      "...." = "cd ../../..";
      "..." = "cd ../..";
      ".." = "cd ..";
      "~" = "cd ~";

      # Editor shortcuts
      code = "code-insiders";
      c = "code-insiders";
      v = "nvim";

      # Tool shortcuts
      kubectl = "kubecolor";
      tf = "terraform";
      g = "git";
      y = "yazi";

      # Enhanced ls
      l = "ls";
      la = "ls -a";
      ll = "ls -la";
      lt = "eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'";

      # System utilities
      sudo = "sudo -E";
      diff = "diff --color";
      grep = "grep -s --color=auto";
      watch = "watch --quiet";

      # macOS compatibility
      nu-open = "open";
      open = "^open";
    };

    environmentVariables = config.home.sessionVariables;
  };

  # XDG configuration files
  xdg.configFile =
    lib.listToAttrs (
      map (module: {
        name = "nushell/${module}";
        value.source = ./core/${module};
      }) (lib.filter (m: m != "theme.nu") coreModules)
    )
    // {
      "nushell/theme.nu".source = ./themes/${nushellTheme};
    };
}
