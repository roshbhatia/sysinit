{ pkgs }:
let
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
in
nativeCheck {
  name = "editor-workbench-check";
  inputs = [
    pkgs.neovim-unwrapped
    pkgs.git
    (pkgs.buildEnv {
      name = "editor-host-profile";
      paths = [
        pkgs.changes
        pkgs.changes-cli
        pkgs.traces
        pkgs.traces-cli
      ];
    })
  ];
  commands = [
    [
      "nvim"
      "--headless"
      "-u"
      "NONE"
      "-l"
      ./editor-workbench.lua
      pkgs.sysinit-editor-workbench
      pkgs.sysinit-reviewr
      pkgs.changes-neovim-plugin
      ../../features/review/source-view.lua
      ../../modules/home/programs/neovim/review-keys.lua
    ]
  ];
}
