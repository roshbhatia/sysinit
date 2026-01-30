{
  pkgs,
  ...
}:

{
  programs.fzf = {
    enable = true;
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
}
