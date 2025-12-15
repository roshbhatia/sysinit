{
  pkgs,
  ...
}:

let
  tomlFormat = pkgs.formats.toml { };

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

  mkPluginConfigs = builtins.listToAttrs (
    map (name: {
      name = "yazi/plugins/${name}";
      value = {
        source = yaziPluginsRepo + "/${name}";
        force = true;
      };
    }) plugins
  );

in
{
  stylix.targets.yazi.enable = true;

  xdg.configFile = mkPluginConfigs // {
    "yazi/yazi.toml" = {
      source = tomlFormat.generate "yazi.toml" yaziConfig;
      force = true;
    };

    "yazi/init.lua".source = ./init.lua;
  };
}
