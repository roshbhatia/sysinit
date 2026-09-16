{
  pkgs,
  ...
}:

let
  yaziConfig = {
    mgr = {
      show_hidden = true;
    };
  };

  plugins = [
    "git.yazi"
    "no-status.yazi"
  ];

  yaziPluginsRepo = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "f9b3f8876eaa74d8b76e5b8356aca7e6a81c0fb7";
    hash = "sha256-0cu5YuuuWqsDbPjyqkVu/dkIBxyhMkR7KbPavzExQtM=";
    sparseCheckout = plugins;
  };

in
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    shellWrapperName = "y";
    settings = yaziConfig // {
      plugin.prepend_fetchers = [
        {
          id = "git";
          name = "*";
          run = "git";
        }
        {
          id = "git";
          name = "*/";
          run = "git";
        }
      ];
    };
    plugins = {
      git = {
        package = yaziPluginsRepo + "/git.yazi";
        setup = true;
      };
      no-status = {
        package = yaziPluginsRepo + "/no-status.yazi";
        setup = true;
      };
    };
  };
}
