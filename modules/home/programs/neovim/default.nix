{ pkgs, ... }:

{
  imports = [ ./sysinit-nvim.nix ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    sideloadInitLua = true;
    plugins = [ pkgs.nvim-nu ];
  };

  home.packages = [
    (pkgs.writeShellApplication {
      name = "rnvim";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.openssh
      ];
      text = builtins.readFile ./scripts/rnvim.sh;
    })
  ];
}
