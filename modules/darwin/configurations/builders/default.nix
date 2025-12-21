{
  nix = {
    buildMachines = [
      {
        hostName = "arrakis";
        system = "aarch64-linux";
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
        maxJobs = 8;
        speedFactor = 2;
        protocol = "ssh-ng";
        sshUser = "rshnbhatia";
        sshKey = "/Users/rshnbhatia/.ssh/id_ed25519";
      }
    ];
    
    settings = {
      builders-use-substitutes = true;
    };
  };
}
