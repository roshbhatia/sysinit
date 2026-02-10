{
  pkgs,
  ...
}:

{
  home.packages = [
    (pkgs.wrapWeechat pkgs.weechat-unwrapped {
      configure =
        { availablePlugins, ... }:
        {
          plugins = (builtins.attrValues (builtins.removeAttrs availablePlugins [ "php" ])) ++ [
            pkgs.weechatScripts.weechat-matrix-rs
          ];
          scripts = with pkgs.weechatScripts; [
            colorize_nicks
            edit
            multiline
            url_hint
            weechat-autosort
            weechat-grep
          ];
        };
    })
  ];
}
