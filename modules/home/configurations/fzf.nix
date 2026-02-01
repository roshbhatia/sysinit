{
  pkgs,
  lib,
  ...
}:

{
  stylix.targets.fzf.colors.override = {
    bg = lib.mkForce "-1";
    "bg+" = lib.mkForce "-1";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = false; # zsh vi mode messes with ZLE, so we manually source it

    defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git --exclude node_modules";
    fileWidgetCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git --exclude node_modules";
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git --exclude node_modules";

    defaultOptions = [
      "--bind=ctrl-d:half-page-down"
      "--bind=ctrl-f:jump,jump:accept"
      "--bind=ctrl-k:toggle-preview"
      "--bind=ctrl-u:half-page-up"
      "--bind=resize:refresh-preview"
      "--bind=shift-tab:up"
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
      "--color=gutter:-1"
      "--color=preview-bg:-1"
    ];

    fileWidgetOptions = [
      "--preview '${pkgs.bat}/bin/bat --style=numbers --color=always --line-range :500 {}'"
    ];

    changeDirWidgetOptions = [
      "--preview '${pkgs.eza}/bin/eza --tree --color=always --level=2 --icons=always {}'"
    ];

    historyWidgetOptions = [
      "--scheme=history"
      "--smart-case"
      "--sort"
      "--height=30%"
    ];
  };
}
