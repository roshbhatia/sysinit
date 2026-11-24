{ pkgs }:
let
  inherit (pkgs) lib;
  commandPath = import ../../modules/shared/command-path.nix { inherit (pkgs) lib; };
  darwinPath = commandPath.entriesFor true "/profile/bin";
  linuxPath = commandPath.entriesFor false "/profile/bin";
  shellPaths = import ../../modules/lib/paths.nix { inherit (pkgs) lib; };
  darwinShellPath = shellPaths.getAllPaths "roshan" "/Users/roshan";
  linuxShellPath = shellPaths.getAllPaths "roshan" "/home/roshan";
  standardSystemPath = [
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
in
assert lib.assertMsg (
  builtins.elemAt darwinPath 3 == "/opt/homebrew/bin"
) "darwin path entry 3 is ${builtins.elemAt darwinPath 3}, not /opt/homebrew/bin";
assert lib.assertMsg (
  builtins.elemAt darwinPath 4 == "/opt/homebrew/sbin"
) "darwin path entry 4 is ${builtins.elemAt darwinPath 4}, not /opt/homebrew/sbin";
assert lib.assertMsg (
  builtins.elemAt darwinPath 5 == "/usr/local/bin"
) "darwin path entry 5 is ${builtins.elemAt darwinPath 5}, not /usr/local/bin";
assert lib.assertMsg (
  !(builtins.elem "/opt/homebrew/bin" linuxPath)
) "the linux path carries /opt/homebrew/bin, which exists only on darwin";
assert lib.assertMsg (builtins.all (path: builtins.elem path darwinShellPath)
  standardSystemPath
) "the darwin shell path drops one of ${builtins.concatStringsSep " " standardSystemPath}";
assert lib.assertMsg (builtins.all (path: builtins.elem path linuxShellPath)
  standardSystemPath
) "the linux shell path drops one of ${builtins.concatStringsSep " " standardSystemPath}";
assert lib.assertMsg (
  commandPath.homeEntriesFor true "/etc/profiles/per-user/roshan/bin" "/Users/roshan"
  == darwinShellPath
  &&
    commandPath.homeEntriesFor false "/etc/profiles/per-user/roshan/bin" "/home/roshan"
    == linuxShellPath
) "agent and shell paths must use the same entries";
assert lib.assertMsg (
  builtins.elem "/Users/roshan/go/bin" darwinShellPath
  && builtins.elem "/home/roshan/go/bin" linuxShellPath
  && builtins.head darwinShellPath == "/etc/profiles/per-user/roshan/bin"
  && builtins.length darwinShellPath == builtins.length (lib.unique darwinShellPath)
) "user tools must be available after managed commands without duplicate paths";
pkgs.runCommand "command-path-order" { } "touch $out"
