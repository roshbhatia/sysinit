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

    vendorHash = "sha256-hGfwb0GZCxc3EQWvxs7/fNVEVGGQE2I0B+MMaH7ecPM=";

    meta = with final.lib; {
      description = "An enum generator for Go";
      homepage = "https://github.com/abice/go-enum";
      license = licenses.mit;
      mainProgram = "go-enum";
    };
  };
}
