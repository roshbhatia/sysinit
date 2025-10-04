{
  lib,
  pkgs,
  values,
  utils,
  ...
}:

let
  inherit (utils.themes) getThemePalette;

  palette = getThemePalette values.theme.colorscheme values.theme.variant;
  semanticColors = utils.themes.utils.createSemanticMapping palette;

  # Build fzf color strings from theme palette
  fg = lib.removePrefix "#" semanticColors.foreground.primary;
  bg = lib.removePrefix "#" semanticColors.background.primary;
  hl = lib.removePrefix "#" (palette.magenta or semanticColors.accent.primary);
  hlPlus = lib.removePrefix "#" (palette.cyan or semanticColors.accent.secondary);
  info = lib.removePrefix "#" (palette.blue or semanticColors.semantic.info);
  marker = lib.removePrefix "#" (palette.green or semanticColors.semantic.success);
  prompt = lib.removePrefix "#" (palette.cyan or semanticColors.accent.secondary);
  spinner = lib.removePrefix "#" (palette.green or semanticColors.semantic.success);
  pointer = lib.removePrefix "#" (palette.cyan or semanticColors.accent.secondary);
  header = lib.removePrefix "#" (palette.green or semanticColors.semantic.success);
  border = lib.removePrefix "#" (palette.cyan or semanticColors.accent.secondary);
in
{
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

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
      "--color=fg:${fg},bg:${bg},hl:${hl}"
      "--color=fg+:${fg},bg+:${bg},hl+:${hlPlus}"
      "--color=info:${info},marker:${marker},prompt:${prompt},spinner:${spinner}"
      "--color=pointer:${pointer},header:${header},gutter:${bg},border:${border}"
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

    tmux = {
      enableShellIntegration = true;
      shellIntegrationOptions = [
        "-p 80%,60%"
      ];
    };
  };
}
