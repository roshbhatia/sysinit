{
  writeShellApplication,
  lib,
  coreutils,
  nushell,
  seshy-cli,
  wezterm,
}:
writeShellApplication {
  name = "ty";
  runtimeInputs = [ coreutils ];
  text = ''
    export SYSINIT_TY_SY="${seshy-cli}/bin/sy"
    export SYSINIT_TY_WEZTERM="${wezterm}/bin/wezterm"
    export SYSINIT_TY_ENV="${coreutils}/bin/env"
    exec ${lib.getExe nushell} --no-config-file ${./ty.nu} "$@"
  '';
}
