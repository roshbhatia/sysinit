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
          plugins = (builtins.attrValues (builtins.removeAttrs availablePlugins [ "php" ]));
          scripts = with pkgs.weechatScripts; [
            colorize_nicks
            edit
            url_hint
            weechat-autosort
            weechat-grep
            weechat-matrix
          ];
        };
    })
  ];
}
