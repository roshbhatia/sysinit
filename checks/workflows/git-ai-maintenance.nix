{ pkgs }:
pkgs.runCommand "git-ai-maintenance"
  {
    nativeBuildInputs = [
      pkgs.nushell
      pkgs.sqlite
      pkgs.coreutils
    ];
  }
  ''
    nu --no-config-file -c 'use ${../../modules/home/programs/git-ai/maintain-metrics.nu} maintain; source ${./git-ai-maintenance.nu}; check ${../../modules/home/programs/git-ai/maintain-metrics.nu} ${../fixtures/wait-for-file.nu}'
    touch "$out"
  ''
