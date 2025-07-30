{
  config,
  lib,
  ...
}:

rec {
  # Centralized path management for all shells and configurations
  getSystemPaths = username: home: {
    # Nix paths - highest priority
    nix = [
      "/nix/var/nix/profiles/default/bin"
      "/etc/profiles/per-user/${username}/bin"
      "/run/current-system/sw/bin/darwin-rebuild"
    ];

    # System paths
    system = [
      "/opt/homebrew/bin"
      "/opt/homebrew/opt/libgit2@1.8/bin"
      "/opt/homebrew/sbin"
      "/usr/bin"
      "/usr/local/opt/cython/bin"
      "/usr/sbin"
    ];

    # User-specific paths
    user = [
      "${home}/.cargo/bin"
      "${home}/.krew/bin"
      "${home}/.local/bin"
      "${home}/.npm-global/bin"
      "${home}/.npm-global/bin/yarn"
      "${home}/.rvm/bin"
      "${home}/.uv/bin"
      "${home}/.yarn/bin"
      "${home}/.yarn/global/node_modules/.bin"
      "${home}/bin"
      "${home}/go/bin"
    ];

    # XDG-based paths
    xdg = [
      "${home}/.config/.cargo/bin"
      "${home}/.config/yarn/global/node_modules/.bin"
      "${home}/.config/zsh/bin"
      "${home}/.local/share/.npm-packages/bin"
    ];
  };

  # Get all paths in order (nix -> system -> user -> xdg)
  getAllPaths =
    username: home:
    let
      paths = getSystemPaths username home;
    in
    paths.nix ++ paths.system ++ paths.user ++ paths.xdg;

  # Generate path string for shells
  getPathString = username: home: lib.concatStringsSep ":" (getAllPaths username home);

  # Generate path array for lua/wezterm
  getPathArray = username: home: getAllPaths username home;
}
