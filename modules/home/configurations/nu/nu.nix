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
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;

  pathsList = paths.getAllPaths config.home.username config.home.homeDirectory;

  moduleGroups = {
    system = [ "theme.nu" ];
    integrations = [
      "atuin.nu"
      "direnv.nu"
      "zoxide.nu"
      "completions.nu"
    ];
    tools = [ "kubectl.nu" ];
    ui = [
      "wezterm.nu"
      "macchina.nu"
      "omp.nu"
    ];
  };

  allModules = lib.flatten (lib.attrValues moduleGroups);

  moduleSourceStatements = lib.concatStringsSep "\n      " (
    map (module: "source ${module}") allModules
  );
in
{
  programs.nushell = {
    enable = true;

    configFile.source = ./system/config.nu;
    envFile.source = ./system/env.nu;

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

      # FZF theme configuration
      $env.FZF_DEFAULT_OPTS = [
        "--bind=resize:refresh-preview"
        "--color=bg+:-1,bg:-1,spinner:${colors.primary},hl:${colors.primary}"
        "--color=border:${colors.border},label:${colors.foreground}"
        "--color=fg:${colors.foreground},header:${colors.primary},info:${colors.muted},pointer:${colors.primary}"
        "--color=marker:${colors.primary},fg+:${colors.foreground},prompt:${colors.primary},hl+:${colors.primary}"
        "--color=preview-bg:-1,query:${colors.foreground}"
        "--cycle"
        "--height=30"
        "--highlight-line"
        "--ignore-case"
        "--info=inline"
        "--input-border=rounded"
        "--layout=reverse"
        "--list-border=rounded"
        "--no-scrollbar"
        "--pointer='>'"
        "--preview-border=rounded"
        "--prompt='>> '"
        "--scheme=history"
        "--style=minimal"
      ] | str join " "
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

  # Generate xdg.configFile entries for all module groups
  xdg.configFile =
    let
      # Create config file entries for each group
      createGroupConfigs =
        groupName: modules:
        lib.listToAttrs (
          map (module: {
            name = "nushell/${module}";
            value.source = ./${groupName}/${module};
          }) (lib.filter (m: m != "theme.nu") modules)
        );

      # Combine all group configs
      allGroupConfigs = lib.foldl' (
        acc: groupName: acc // createGroupConfigs groupName moduleGroups.${groupName}
      ) { } (lib.attrNames moduleGroups);
    in
    allGroupConfigs
    // {
      "nushell/theme.nu".source = ./themes/${nushellTheme};
    };
}

