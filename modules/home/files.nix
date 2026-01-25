{
  pkgs,
  ...
}:

let
  # === Yazi ===
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
  # === Bat: Better cat ===
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };

  # === Eza: Better ls ===
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    git = true;
    icons = "auto";
    colors = "auto";

    extraOptions = [
      "--time-style=long-iso"
    ];
  };

  # === FD: Better find ===
  programs.fd = {
    enable = true;
    hidden = true;
    extraOptions = [
      "--follow"
      "--no-ignore-vcs"
    ];
    ignores = [
      ".git/"
      "node_modules/"
      ".direnv/"
      ".devenv/"
      "target/"
      "dist/"
      "build/"
      ".DS_Store"
      "*.pyc"
      "__pycache__/"
      ".venv/"
      ".env/"
    ];
  };

  # === Yazi: Terminal file manager ===
  xdg.configFile = mkPluginConfigs // {
    "yazi/yazi.toml" = {
      source = tomlFormat.generate "yazi.toml" yaziConfig;
      force = true;
    };

    "yazi/init.lua".source = ./configurations/yazi/init.lua;
  };
}
