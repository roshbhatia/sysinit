{ ... }:

final: _prev:
let
  sources = final.nvfetcherSources.go-enum;
  version = final.lib.removePrefix "v" sources.version;
in
{
  go-enum = final.buildGoModule {
    pname = "go-enum";
    inherit version;

    inherit (sources) src;

    vendorHash = "sha256-YzIVI+PLZt24s/KjTxifWrvjrIU8jLvkC1lgw4yG6cg=";

    meta = with final.lib; {
      description = "An enum generator for Go";
      homepage = "https://github.com/abice/go-enum";
      license = licenses.mit;
      mainProgram = "go-enum";
    };
  };
}
