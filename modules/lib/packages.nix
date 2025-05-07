{ pkgs, lib, ... }:

{
  systemPackages = with pkgs; [
    oh-my-posh
    k9s
    nil
    nixfmt-rfc-style
    nushell
  ];
}
