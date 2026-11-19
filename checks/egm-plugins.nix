{ pkgs, home }:
pkgs.runCommand "egm-plugin-bundle"
  {
    nativeBuildInputs = [
      pkgs.nushell
      pkgs.coreutils
    ];
  }
  ''
    nu --no-config-file ${./.}/egm-plugins-runner.nu "$out" ${home.programs.codex.marketplaces.egm} ${
      home.home.file.".claude/skills/egm".source
    } ${home.home.file.".codex/config.toml".source} ${./egm-plugins.nu}
  ''
