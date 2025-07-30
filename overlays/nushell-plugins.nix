{
  ...
}:

final: prev: {
  nushellPlugins = prev.nushellPlugins // {
    nu_plugin_cloud = final.rustPlatform.buildRustPackage rec {
      pname = "nu_plugin_cloud";
      version = "0.2.0";

      src = final.fetchCrate {
        inherit pname version;
        hash = "sha256-1g6y8478jkjml4chp1dn5j44wkxb2bcb6pprh4vdpzvpc72lywai";
      };

      cargoHash = "sha256-0000000000000000000000000000000000000000000=";

      meta = with final.lib; {
        description = "A nushell plugin for interacting with cloud providers";
        homepage = "https://crates.io/crates/nu_plugin_cloud";
        license = licenses.mit;
        maintainers = with maintainers; [ ];
      };

      buildFeatures = [ ];
      doCheck = false;

      postInstall = ''
        if [ -f "$out/bin/nu_plugin_cloud" ]; then
          echo "Plugin nu_plugin_cloud installed successfully"
        fi
      '';
    };
  };
}
