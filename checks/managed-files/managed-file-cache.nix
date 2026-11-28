{ pkgs }:
let
  helper = import ../../features/managed-files/managed-file.nix { inherit (pkgs) lib; };
  entry = {
    enable = true;
    path = ".config/test.json";
    format = "json";
    contentFile = null;
    content = {
      owned = true;
    };
    schema = null;
    enforce = [ "owned" ];
    retire = [ "retired" ];
    createIfMissing = true;
  };
  runner = helper.mkReconciler {
    inherit pkgs;
    files.test = entry;
    files.other = entry // {
      path = ".config/other.json";
    };
  };
in
pkgs.runCommand "managed-file-cache-test" { nativeBuildInputs = [ pkgs.nushell ]; } ''
  nu --no-config-file ${./managed-file-cache.nu} ${runner}/bin/sysinit-llm-reconcile ${../../features/managed-files/managed-file-cache.nu}
  touch "$out"
''
