{
  description = "Work system configuration using SysInit";

  inputs = {
    # Reference to the main SysInit flake
    # For GitHub:
    sysinit.url = "github:roshbhatia/sysinit";
    # For local development:
    # sysinit.url = "/path/to/sysinit";
    
    # Inherit inputs from sysinit to ensure compatibility
    nixpkgs.follows = "sysinit/nixpkgs";
    darwin.follows = "sysinit/darwin";
    home-manager.follows = "sysinit/home-manager";
  };

  outputs = { self, nixpkgs, darwin, home-manager, sysinit }: {
    # Create a darwin configuration using the work config.nix
    darwinConfigurations.default = sysinit.lib.mkConfigWithFile ./config.nix;
    
    # You can also create a hostname-specific configuration
    # darwinConfigurations."work-macbook" = sysinit.lib.mkConfigWithFile ./config.nix;
  };
}