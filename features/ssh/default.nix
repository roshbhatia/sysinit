{
  flake.modules = {
    homeManager.openssh = ./home.nix;
    homeManager.opensshClient = ./client.nix;
    darwin.personalOpenSSH = ./darwin.nix;
    nixos.workstationOpenSSH = ./nixos.nix;
  };
}
