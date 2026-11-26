{ pkgs }:
pkgs.runCommand "nh-darwin-output-path"
  {
    nativeBuildInputs = [
      pkgs.nushell
      pkgs.coreutils
    ];
  }
  (
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''
        nu --no-config-file ${./nh.nu} ${pkgs.nh}/bin/nh ${../fixtures/nh-command.nu}
        touch "$out"
      ''
    else
      ''
        touch "$out"
      ''
  )
