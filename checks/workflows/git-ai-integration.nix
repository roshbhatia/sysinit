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
      ${../../modules/home/programs/nushell/attribution.nu} ${../../modules/home/programs/nushell/storage.nu}
    touch "$out"
  ''
