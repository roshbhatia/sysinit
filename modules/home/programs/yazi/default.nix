{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    shellWrapperName = "y";
    settings = {
      mgr.show_hidden = true;
      plugin.prepend_fetchers = [
        {
          group = "git";
          url = "*";
          run = "git";
        }
        {
          group = "git";
          url = "*/";
          run = "git";
        }
      ];
    };
    plugins = {
      git = {
        package = pkgs.yaziPlugins.git;
        setup = true;
      };
      no-status = {
        package = pkgs.yaziPlugins.no-status;
        setup = true;
      };
    };
  };
}
