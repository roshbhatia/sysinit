{ lib, ... }:

let
  # `modules/shared/command-path.nix` owns the system segment: the Nix
  # profiles, the Linux-only wrappers directory, Homebrew, and the /usr
  # fallbacks. Repeating those lists here let the two drift, and this copy had
  # picked up /run/wrappers/bin on Darwin, where the directory does not exist.
  commandPath = import ../shared/command-path.nix { inherit lib; };

  # wezterm imports this file with `lib` alone, so Darwin is read off the home
  # directory rather than a `pkgs` the three call sites do not pass. This is a
  # string test, not a platform test: a Linux host with a `/Users/` home would
  # read as Darwin here.
  isDarwin = home: lib.hasPrefix "/Users/" home;

  getSystemPaths = username: home: {
    system = commandPath.entriesFor (isDarwin home) "/etc/profiles/per-user/${username}/bin";

    # Keg-only Homebrew formulae. They are not on the shared system path
    # because only interactive shells need them.
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
