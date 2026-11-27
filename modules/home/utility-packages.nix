{
  lib,
  pkgs,
  profile ? "workstation",
  ...
}:
let
  script =
    name: source: dependencies:
    pkgs.sysinit.writeShellApplication {
      inherit name;
      runtimeInputs = dependencies;
      text = ''
        ${
          if pkgs.stdenv.hostPlatform.isDarwin then
            ''export PATH="$PATH:/usr/bin:/bin:/usr/sbin:/sbin"''
          else
            ''export PATH="/run/wrappers/bin:$PATH"''
        }
        exec ${lib.getExe pkgs.nushell} --no-config-file ${source} "$@"
      '';
    };
  audio = script "audio-switcher" ../../features/desktop/audio-switcher.nu (
    [ pkgs.fzf ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.switchaudio-osx ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.pulseaudio ]
  );
in
{
  home.packages = [
    (script "dns-flush" ../../features/network/dns-flush.nu (
      lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.systemd ]
    ))
    (script "fzf-preview" ../../features/cli/fzf-preview.nu [
      pkgs.file
      pkgs.eza
      pkgs.chafa
      pkgs.ncurses
      pkgs.bat
      pkgs.gnutar
      pkgs.gzip
      pkgs.bzip2
      pkgs.unzip
      pkgs._7zz
      pkgs.coreutils
    ])
  ]
  ++ lib.optionals (profile == "workstation") [
    (script "connect" ../../features/wezterm/connect.nu [ pkgs.wezterm ])
    (script "set-background" ../../features/theme/set-background.nu (
      [
        pkgs.fzf
        pkgs.chafa
        pkgs.gh
        pkgs.fd
        pkgs.git
        pkgs.coreutils
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.sway ]
    ))
    audio
  ];
}
