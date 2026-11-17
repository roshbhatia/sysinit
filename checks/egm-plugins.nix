{ pkgs, home }:
pkgs.runCommand "egm-plugin-bundle" { nativeBuildInputs = [ pkgs.nushell ]; } ''
  mkdir -p "$out"
  ln -s ${home.programs.codex.marketplaces.egm} "$out/bundle"
  ln -s ${home.home.file.".claude/skills/egm".source} "$out/claude"
  ln -s ${home.home.file.".codex/config.toml".source} "$out/config.toml"
  nu --no-config-file ${./egm-plugins.nu} "$out"
''
