{ pkgs, lib, ... }:

{
  systemPackages = with pkgs; [
    findutils
  ];

  environment.extraInit = ''
    export PATH="${pkgs.findutils}/bin:$PATH"
  '';
}
