{ ... }:

{
  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes auto-allocate-uids impure-derivations dynamic-derivations
  '';
}
