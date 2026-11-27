{
  flake.modules.homeManager = {
    java = ./java.nix;
    mise = ./mise.nix;
    terraform = ./terraform.nix;
  };
}
