{
  pkgs,
  ...
}:

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
      "--color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7"
      "--color=fg+:#c0caf5,bg+:#1a1b26,hl+:#7dcfff"
      "--color=info:#7aa2f7,marker:#9ece6a,prompt:#7dcfff,spinner:#9ece6a"
      "--color=pointer:#7dcfff,header:#9ece6a,gutter:#1a1b26,border:#27a1b9"
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
