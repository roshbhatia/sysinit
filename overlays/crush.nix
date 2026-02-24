_:

final: _prev:
let
  # crush 0.44.0 requires Go 1.26+
  buildGoModule = final.buildGoModule.override { go = final.go_1_26; };
in
{
  crush = buildGoModule rec {
    pname = "crush";
    version = "0.44.0";

    src = final.fetchFromGitHub {
      owner = "charmbracelet";
      repo = "crush";
      rev = "v${version}";
      hash = "sha256-UyK03jnD6A5/NO/evG56dbn8GyDyVSnfFgdxl5toH14=";
    };

    # Let Nix handle vendoring - upstream vendor dir is out of sync
    vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    proxyVendor = true;

    meta = with final.lib; {
      description = "A shared key-value store for the terminal";
      homepage = "https://github.com/charmbracelet/crush";
      license = licenses.mit;
      mainProgram = "crush";
    };
  };
}
