{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs.buildPackages; [ 
      go_1_24
      macchina
    ];
    
    shellHook = ''
      macchina --theme nix
    '';
}