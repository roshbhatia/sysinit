# overlays/nushell-plugins.nix
# Purpose: Nushell plugin overlays for custom and bleeding-edge plugins
# This overlay adds custom Nushell plugins not available in nixpkgs

{
  ...
}:

final: prev: {
  # Custom Nushell plugins
  nushellPlugins = prev.nushellPlugins // {
    # nu_plugin_cloud - Cloud provider utilities for Nushell
    nu_plugin_cloud = final.rustPlatform.buildRustPackage rec {
      pname = "nu_plugin_cloud";
      version = "0.2.0";

      src = final.fetchCrate {
        inherit pname version;
        hash = "sha256-1g6y8478jkjml4chp1dn5j44wkxb2bcb6pprh4vdpzvpc72lywai";
      };

      cargoHash = "sha256-0000000000000000000000000000000000000000000="; # Will be updated after first build

      meta = with final.lib; {
        description = "A nushell plugin for interacting with cloud providers";
        homepage = "https://crates.io/crates/nu_plugin_cloud";
        license = licenses.mit;
        maintainers = with maintainers; [ ];
      };

      # Build configuration specific to nushell plugins
      buildFeatures = [ ];
      doCheck = false; # Disable tests for now

      postInstall = ''
        # Ensure the plugin binary is properly named
        if [ -f "$out/bin/nu_plugin_cloud" ]; then
          # Plugin is correctly named
          echo "Plugin nu_plugin_cloud installed successfully"
        fi
      '';
    };
  };
}
