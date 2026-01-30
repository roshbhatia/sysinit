{
  pkgs,
  lib,
  ...
}:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # Broken? We add it to our config directly anyways below.

    defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git --exclude node_modules";
    fileWidgetCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git --exclude node_modules";
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git --exclude node_modules";

    defaultOptions = [
      "--style=minimal"
      "--layout=reverse"
      "--height=80%"
      "--info=inline"
      "--scheme=history"
      "--border=rounded"
      "--preview-window=right:50%:wrap"
      "--bind=resize:refresh-preview"
      "--bind=ctrl-/:toggle-preview"
      "--bind=ctrl-d:half-page-down"
      "--bind=ctrl-u:half-page-up"
      "--color=bg+:-1,bg:-1"
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

  programs.zsh.initContent = lib.mkAfter "source <(fzf --zsh)";
}
