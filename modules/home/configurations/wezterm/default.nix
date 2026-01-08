{
  config,
  values,
  lib,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };
  themeNames = import ../../../shared/lib/theme/adapters/theme-names.nix { inherit lib; };
  themeName = themeNames.getWeztermTheme values.theme.colorscheme values.theme.variant;

  # Shared PATH configuration (same as zsh)
  systemPaths = {
    nix = [
      "/nix/var/nix/profiles/default/bin"
      "/etc/profiles/per-user/${config.home.username}/bin"
      "/run/wrappers/bin"
      "/run/current-system/sw/bin"
    ];
    system = [
      "/opt/homebrew/bin"
      "/opt/homebrew/opt/libgit2@1.8/bin"
      "/opt/homebrew/sbin"
      "/usr/bin"
      "/usr/local/opt/cython/bin"
      "/usr/sbin"
    ];
    user = [
      "${config.home.homeDirectory}/.cargo/bin"
      "${config.home.homeDirectory}/.krew/bin"
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.npm-global/bin"
      "${config.home.homeDirectory}/.npm-global/bin/yarn"
      "${config.home.homeDirectory}/.rvm/bin"
      "${config.home.homeDirectory}/.uv/bin"
      "${config.home.homeDirectory}/.yarn/bin"
      "${config.home.homeDirectory}/.yarn/global/node_modules/.bin"
      "${config.home.homeDirectory}/bin"
      "${config.home.homeDirectory}/go/bin"
    ];
    xdg = [
      "${config.home.homeDirectory}/.config/.cargo/bin"
      "${config.home.homeDirectory}/.config/yarn/global/node_modules/.bin"
      "${config.home.homeDirectory}/.config/zsh/bin"
      "${config.home.homeDirectory}/.local/share/.npm-packages/bin"
    ];
  };

  pathsList = systemPaths.nix ++ systemPaths.system ++ systemPaths.user ++ systemPaths.xdg;
in
{
  stylix.targets.wezterm.enable = false;

  xdg.configFile = {
    "wezterm/wezterm.lua".source = ./wezterm.lua;
    "wezterm/lua".source = ./lua;
    "wezterm/config.json".text = themes.toJsonFile (
      themes.makeThemeJsonConfig values {
        color_scheme = themeName;
        paths = pathsList;
      }
    );
    "wezterm/colors/kanso-ink.lua".source = ./colors/kanso-ink.lua;
    "wezterm/colors/kanso-mist.lua".source = ./colors/kanso-mist.lua;
  };
}
