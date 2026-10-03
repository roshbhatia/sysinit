{ lib }:
let
  nixEntries = [
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
  ];

  fallbackEntries = [
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];

  systemEntriesFor =
    isDarwin:
    lib.optionals (!isDarwin) [ "/run/wrappers/bin" ]
    ++ nixEntries
    ++ lib.optionals isDarwin [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ]
    ++ fallbackEntries;

  entriesFor = isDarwin: profileBin: [ profileBin ] ++ systemEntriesFor isDarwin;
  userPathsFor = isDarwin: home: {
    kegOnly = lib.optionals isDarwin [
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
  homeEntriesFor =
    isDarwin: profileBin: home:
    let
      paths = userPathsFor isDarwin home;
    in
    lib.unique (entriesFor isDarwin profileBin ++ paths.kegOnly ++ paths.user ++ paths.xdg);
in
{
  inherit entriesFor systemEntriesFor homeEntriesFor;
  renderHomeFor =
    isDarwin: profileBin: home:
    lib.concatStringsSep ":" (homeEntriesFor isDarwin profileBin home);
  renderFor = isDarwin: profileBin: lib.concatStringsSep ":" (entriesFor isDarwin profileBin);
}
