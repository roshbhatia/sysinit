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
    ./users.nix
    ./networking.nix
    ./virtualisation.nix
    ./xdg.nix
    ./services.nix
    ./compat.nix
    ./stylix
  ];
}
