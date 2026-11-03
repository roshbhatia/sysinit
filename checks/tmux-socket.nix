{
  pkgs,
  lib,
  homeConfigurations,
}:
let
  profile = homeConfigurations.${"dev-" + pkgs.stdenv.hostPlatform.system}.extendModules {
    modules = [
      {
        programs.tmux.enable = true;
        programs.tmux.secureSocket = true;
      }
    ];
  };
  socketLine =
    lib.findFirst (line: lib.hasInfix "$env.TMUX_TMPDIR =" line)
      (throw "tmux runtime socket translation is missing")
      (lib.splitString "\n" profile.config.programs.nushell.extraConfig);
  source = pkgs.writeText "tmux-socket.nu" socketLine;
in
pkgs.runCommand "tmux-nushell-socket-test"
  {
    nativeBuildInputs = [
      pkgs.nushell
      pkgs.coreutils
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    unset XDG_RUNTIME_DIR TMUX_TMPDIR
    actual=$(nu -n -c 'source ${source}; print $env.TMUX_TMPDIR')
    test "$actual" = "/run/user/$(id -u)"
    actual=$(XDG_RUNTIME_DIR="$TMPDIR/runtime" nu -n -c 'source ${source}; print $env.TMUX_TMPDIR')
    test "$actual" = "$TMPDIR/runtime"
    touch "$out"
  ''
