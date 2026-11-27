{ pkgs }:
let
  inherit (pkgs) lib;
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
in
nativeCheck {
  name = "nushell-utilities";
  environment.TASK_BINARY = lib.getExe pkgs.taskwarrior-cli;
  commands = [
    [
      "nu"
      "--no-config-file"
      "-c"
      "use ${../../modules/home/programs/utils/dev/ere-setup.nu} configure; use ${../../modules/home/programs/utils/dev/task-context.nu} [backup restore]; use ${../../modules/home/programs/utils/system/cache-maintain.nu} [maintain allocated-bytes]; source ${./nushell-utilities.nu}"
    ]
    [
      "nu"
      "--no-config-file"
      "${../workflows/ty.nu}"
      "${../../modules/home/programs/utils/dev/ty.nu}"
      "${../../features/nushell/wezterm.nu}"
    ]
  ];
}
