{ ... }:

{
  imports = [
    ./boot.nix
    ./display.nix
    ./gpu.nix
    ./audio.nix
    ./gaming.nix
    ./shell.nix
    ./ssh.nix
    ./tailscale.nix
    ./sunshine.nix
    ./users.nix
    ./stylix
  ];
}
