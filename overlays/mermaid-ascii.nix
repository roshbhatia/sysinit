_:

final: _prev:
let
  sources = final.nvfetcherSources.mermaid-ascii;
in
{
  mermaid-ascii = final.buildGoModule {
    pname = "mermaid-ascii";
    inherit (sources) version;

    inherit (sources) src;

    vendorHash = "sha256-aB9sbTtlHbptM2995jizGFtSmEIg3i8zWkXz1zzbIek=";

    meta = with final.lib; {
      description = "Render mermaid diagrams as ASCII";
      homepage = "https://github.com/AlexanderGrooff/mermaid-ascii";
      license = licenses.mit;
      mainProgram = "mermaid-ascii";
    };
  };
}
