{ lib, ... }:

let

  commandPath = import ../shared/command-path.nix { inherit lib; };

  isDarwin = home: lib.hasPrefix "/Users/" home;

  getSystemPaths = username: home: {
    system = commandPath.entriesFor (isDarwin home) "/etc/profiles/per-user/${username}/bin";

    kegOnly = lib.optionals (isDarwin home) [
      "/opt/homebrew/opt/libgit2@1.8/bin"
      "/usr/local/opt/cython/bin"
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
    paths.system ++ paths.kegOnly ++ paths.user ++ paths.xdg;
in
{
  inherit getAllPaths;
  getPathString = username: home: lib.concatStringsSep ":" (getAllPaths username home);
}
