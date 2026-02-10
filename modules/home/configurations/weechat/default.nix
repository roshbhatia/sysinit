{
  pkgs,
  ...
}:

{
  programs.weechat = {
    enable = true;
    scripts = with pkgs.weechatScripts; [
      colorize_nicks
      edit
      multiline
      url_hint
      weechat-autosort
      weechat-grep
      weechat-matrix-rs
    ];
  };
}
