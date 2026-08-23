{ lib, ... }:

let
  # wezterm imports this file with `lib` alone, so Darwin is read off the home
  # directory rather than a `pkgs` the three call sites do not pass.
  isDarwin = home: lib.hasPrefix "/Users/" home;

  getSystemPaths = username: home: {
    nix = [
      "/nix/var/nix/profiles/default/bin"
      "/etc/profiles/per-user/${username}/bin"
      "/run/wrappers/bin"
      "/run/current-system/sw/bin"
    ];
    system =
      lib.optionals (isDarwin home) [
        "/opt/homebrew/bin"
        "/opt/homebrew/opt/libgit2@1.8/bin"
        "/opt/homebrew/sbin"
      ]
      ++ [ "/usr/bin" ]
      ++ lib.optionals (isDarwin home) [ "/usr/local/opt/cython/bin" ]
      ++ [ "/usr/sbin" ];
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
in
{
  inherit getAllPaths;
  getPathString = username: home: lib.concatStringsSep ":" (getAllPaths username home);
}
