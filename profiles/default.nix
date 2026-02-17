{ ... }:

{
  base = import ./base.nix;
  desktop = import ./desktop.nix;
  host-minimal = import ./host-minimal.nix;
  dev-full = import ./dev-full.nix;
  dev-minimal = import ./dev-minimal.nix;
}
