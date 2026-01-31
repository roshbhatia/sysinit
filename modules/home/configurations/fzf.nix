{
  pkgs,
  ...
}:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git --exclude node_modules";
    fileWidgetCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git --exclude node_modules";
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git --exclude node_modules";

    colors = {
      bg = "-1";
      "bg+" = "-1";
      gutter = "-1";
      "preview-bg" = "-1";
    };

    defaultOptions = [
      "--bind=ctrl-/:toggle-preview"
      "--bind=ctrl-d:half-page-down"
      "--bind=ctrl-u:half-page-up"
      "--bind=resize:refresh-preview"
      "--border=rounded"
      "--height=80%"
      "--info=inline"
      "--layout=reverse"
      "--preview-window=right:50%:wrap"
      "--scheme=history"
      "--style=minimal"
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
}
