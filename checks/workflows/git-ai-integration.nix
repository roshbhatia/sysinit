{ pkgs }:
pkgs.runCommand "git-ai-integration"
  {
    nativeBuildInputs = [
      pkgs.git
      pkgs.changes
      pkgs.traces
      pkgs.traces-providers
      pkgs.git-ai
      pkgs.nushell
      pkgs.coreutils
    ];
  }
  ''
    nu --no-config-file ${./git-ai-integration.nu} ${pkgs.git-ai}/bin/git-ai ${pkgs.git-ai-gate}/bin/git-ai-gate \
      ${../../modules/home/programs/git-ai/changes-provider.nu} \
      ${../../features/nushell/attribution.nu} ${../../features/nushell/storage.nu}
    touch "$out"
  ''
