{ lib, ... }:

rec {
  getSystemPaths = username: home: {
    nix = [
      "/nix/var/nix/profiles/default/bin"
      "/etc/profiles/per-user/${username}/bin"
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
    xdg = [
      "${home}/.config/.cargo/bin"
      "${home}/.config/yarn/global/node_modules/.bin"
      "${home}/.config/zsh/bin"
      "${home}/.local/share/.npm-packages/bin"
    ];
  };
  getAllPaths =
    username: home:
    let
      paths = getSystemPaths username home;
    in
    paths.nix ++ paths.system ++ paths.user ++ paths.xdg;
  getPathString = username: home: lib.concatStringsSep ":" (getAllPaths username home);
  getPathArray = username: home: getAllPaths username home;
}
