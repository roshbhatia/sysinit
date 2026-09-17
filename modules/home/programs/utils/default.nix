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
  audio = pkgs.sysinit.writeShellApplication {
    name = "audio-switcher";
    runtimeInputs = [
      pkgs.fzf
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.switchaudio-osx ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.pulseaudio ];
    text = ''exec ${pkgs.sysinit-gotools}/bin/audio-switcher "$@"'';
  };
in
{
  home.packages = [
    (script "dns-flush" ./network/dns-flush.nu (
      lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.systemd ]
    ))
    (script "fzf-preview" ./dev/fzf-preview.nu [
      pkgs.file
      pkgs.eza
      pkgs.chafa
      pkgs.ncurses
      pkgs.bat
      pkgs.gnutar
      pkgs.unzip
      pkgs._7zz
      pkgs.coreutils
    ])
  ]
  ++ lib.optionals (profile == "workstation") [
    (script "connect" ./dev/connect.nu [ pkgs.wezterm ])
    (script "set-background" ./system/set-background.nu (
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
