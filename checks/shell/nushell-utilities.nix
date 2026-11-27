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
      "use ${../../features/cli/ere-setup.nu} configure; use ${../../features/taskwarrior/task-context.nu} [backup restore]; use ${../../modules/darwin/home/cache-maintain.nu} [maintain allocated-bytes]; source ${./nushell-utilities.nu}"
    ]
    [
      "nu"
      "--no-config-file"
      "${../workflows/ty.nu}"
      "${../../features/wezterm/ty.nu}"
      "${../../features/nushell/wezterm.nu}"
    ]
  ];
}
