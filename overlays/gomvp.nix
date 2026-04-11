_:

final: _prev:
let
  sources = final.nvfetcherSources.gomvp;
  version = final.lib.removePrefix "v" sources.version;
in
{
  gomvp = final.buildGoModule {
    pname = "gomvp";
    inherit version;

    inherit (sources) src;

    vendorHash = null;

    meta = with final.lib; {
      description = "Refactoring tool for moving Go packages";
      homepage = "https://github.com/abenz1267/gomvp";
      license = licenses.mit;
      mainProgram = "gomvp";
    };
  };
}
