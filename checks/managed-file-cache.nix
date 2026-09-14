{ pkgs }:
let
  helper = import ../modules/home/programs/llm/lib/managed-file.nix { inherit (pkgs) lib; };
  runner = helper.mkReconciler {
    inherit pkgs;
    files.test = {
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
  };
in
pkgs.runCommand "managed-file-cache-test" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python3 ${./managed-file-cache.py} ${runner}/bin/sysinit-llm-reconcile ${../modules/home/programs/llm/lib/managed-file-cache.py}
  touch "$out"
''
