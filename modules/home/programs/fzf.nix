{
  pkgs,
  lib,
  config,
  ...
}:
let
  # The palette, read through one accessor rather than reached for directly.
  # `config.lib.stylix.colors` does not exist on a box without the stylix
  # module, where the dereference is an evaluation error and not a missing color.
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  themeEnabled = themeLib.enabled config;
in

{
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = false; # zsh vi mode messes with ZLE, so we manually source it

    defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git --exclude node_modules";

    defaultOptions = [
      "--multi"
      "--bind=ctrl-d:half-page-down"
      "--bind=ctrl-f:jump,jump:toggle"
      "--bind=ctrl-k:toggle-preview"
      "--bind=ctrl-u:half-page-up"
      "--bind=resize:refresh-preview"
      "--bind=shift-tab:up"
      "--bind=space:toggle"
      "--bind=tab:down"
      "--border=none"
      "--gutter=' '"
      "--height=80%"
      "--info=inline"
      "--jump-labels=fjdkslaghrueiwoncmv"
      "--layout=reverse"
      "--no-hscroll"
      "--preview-window=right:50%:wrap"
      "--style=minimal"
    ];

    fileWidget = {
      command = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git --exclude node_modules";
      options = [
        "--preview '${pkgs.bat}/bin/bat --style=numbers --color=always --line-range :500 {}'"
      ];
    };

    changeDirWidget = {
      command = "${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git --exclude node_modules";
      options = [
        "--preview '${pkgs.eza}/bin/eza --tree --color=always --level=2 --icons=always {}'"
      ];
    };

    historyWidget.options = [
      "--scheme=history"
      "--smart-case"
      "--sort"
      "--height=30%"
    ];

    colors = lib.mkForce (
      lib.optionalAttrs themeEnabled {
        fg = "#${themeColors.base05}";
        "fg+" = "#${themeColors.base06}";
        hl = "#${themeColors.base0D}";
        "hl+" = "#${themeColors.base0D}";
        info = "#${themeColors.base0A}";
        prompt = "#${themeColors.base0D}";
        pointer = "#${themeColors.base0D}";
        marker = "#${themeColors.base0D}";
        spinner = "#${themeColors.base0D}";
        header = "#${themeColors.base0A}";
      }
      // {
        bg = "-1";
        "bg+" = "-1";
        gutter = "-1";
        "preview-bg" = "-1";
      }
    );
  };
}
