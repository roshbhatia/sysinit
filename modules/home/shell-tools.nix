{
  lib,
  pkgs,
  values,
  utils,
  ...
}:

let
  # === Atuin ===
  themes = import ../shared/lib/theme.nix { inherit lib; };
  atuinAdapter = import ./configurations/atuin/impl.nix { inherit lib; };

  validatedTheme = values.theme;
  theme = themes.getTheme validatedTheme.colorscheme;

  atuinThemeConfig = atuinAdapter.createAtuinTheme theme validatedTheme;
  themeName = atuinThemeConfig.atuinThemeName;

  # === Dircolors/Vivid ===
  inherit (utils.theme) mkThemedConfig;

  themeCfg = mkThemedConfig values "vivid" { };
  vividTheme = themeCfg.appTheme;
in
{
  # === Atuin: Shell history ===
  programs.atuin = {
    enable = true;
    enableZshIntegration = false;
    enableNushellIntegration = true;

    settings = {
      update_check = false;
      inline_height = 15;
      show_help = false;
      show_tabs = false;
      enter_accept = true;
      invert = true;
      keymap_mode = "vim-normal";
      show_preview = true;
      style = "compact";
      theme = {
        name = themeName;
      };

      history_filter = [
        "with-env .*atuin search.*"
      ];
    };
  };

  xdg.configFile."atuin/themes/${themeName}.toml" = {
    text = atuinThemeConfig.atuinToml;
    force = true;
  };

  # === Carapace: Completions ===
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  # === Dircolors: Directory colors ===
  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  home.sessionVariables = {
    LS_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
    DIR_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
    EZA_COLORS = "$(${pkgs.vivid}/bin/vivid generate ${vividTheme})";
  };

  # === Direnv: Environment management ===
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };

  # === FZF: Fuzzy finder ===
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    fileWidgetCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git --exclude node_modules";
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git --exclude node_modules";

    defaultOptions = [
      "--height=60%"
      "--layout=reverse"
      "--border=rounded"
      "--info=inline"
      "--preview-window=right:50%:wrap"
      "--bind=ctrl-/:toggle-preview"
      "--bind=ctrl-d:half-page-down"
      "--bind=ctrl-u:half-page-up"
      "--bind=ctrl-f:page-down"
      "--bind=ctrl-b:page-up"
      "--bind=ctrl-a:select-all"
      "--bind=ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort"
    ];

    fileWidgetOptions = [
      "--preview '${pkgs.bat}/bin/bat --style=numbers --color=always --line-range :500 {}'"
    ];

    changeDirWidgetOptions = [
      "--preview '${pkgs.eza}/bin/eza --tree --color=always --level=2 --icons=always {}'"
    ];

    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
  };

  # === Vivid: LS_COLORS generator (theme files) ===
  xdg.configFile = {
    "vivid/themes/black-metal-gorgoroth.yml".source =
      ./configurations/vivid/themes/black-metal-gorgoroth.yml;
    "vivid/themes/everforest-dark-hard.yml".source =
      ./configurations/vivid/themes/everforest-dark-hard.yml;
    "vivid/themes/everforest-dark-medium.yml".source =
      ./configurations/vivid/themes/everforest-dark-medium.yml;
    "vivid/themes/everforest-dark-soft.yml".source =
      ./configurations/vivid/themes/everforest-dark-soft.yml;
    "vivid/themes/everforest-light-hard.yml".source =
      ./configurations/vivid/themes/everforest-light-hard.yml;
    "vivid/themes/everforest-light-medium.yml".source =
      ./configurations/vivid/themes/everforest-light-medium.yml;
    "vivid/themes/everforest-light-soft.yml".source =
      ./configurations/vivid/themes/everforest-light-soft.yml;
    "vivid/themes/kanagawa-dragon.yml".source = ./configurations/vivid/themes/kanagawa-dragon.yml;
    "vivid/themes/kanagawa-lotus.yml".source = ./configurations/vivid/themes/kanagawa-lotus.yml;
    "vivid/themes/kanagawa-wave.yml".source = ./configurations/vivid/themes/kanagawa-wave.yml;
    "vivid/themes/kanso-zen.yml".source = ./configurations/vivid/themes/kanso-zen.yml;
    "vivid/themes/kanso-ink.yml".source = ./configurations/vivid/themes/kanso-ink.yml;
    "vivid/themes/kanso-mist.yml".source = ./configurations/vivid/themes/kanso-mist.yml;
    "vivid/themes/kanso-pearl.yml".source = ./configurations/vivid/themes/kanso-pearl.yml;
  };

  # === Zoxide: Smart directory jumper ===
  programs.zoxide = {
    enable = true;
    enableZshIntegration = false; # Handled manually in zsh config
    enableNushellIntegration = true;
    options = [
      "--cmd cd"
    ];
  };
}
