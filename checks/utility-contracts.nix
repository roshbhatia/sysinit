{ pkgs }:
pkgs.runCommand "utility-contracts"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.nushell
      pkgs.zsh
      pkgs.lua5_4
      pkgs.gnutar
      pkgs.gzip
      pkgs.bzip2
      pkgs._7zz
      pkgs.logrotate
      pkgs.coreutils
    ];
  }
  ''
    python3 ${./utility-contracts.py} ${../.}
    lua ${./desktop-contracts.lua} ${../.}
    python3 ${./log-retention.py}
    touch "$out"
  ''
