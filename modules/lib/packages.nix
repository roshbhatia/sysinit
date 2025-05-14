{ pkgs, lib, ... }:

{
  systemPackages = with pkgs; [
    findutils
  ];

  extraInit = ''
    export PATH="${pkgs.findutils}/bin:$PATH"
  '';
}

