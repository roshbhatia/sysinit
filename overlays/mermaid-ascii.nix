final: _prev:
let
  sources = final.nvfetcherSources.mermaid-ascii;
in
{
  mermaid-ascii = final.buildGoModule {
    pname = "mermaid-ascii";
    inherit (sources) version;

    inherit (sources) src;

    vendorHash = "sha256-S/K6W8KC6YzwZPioucoiwOMd29LPv0J22T3MS0X+W5g=";

    meta = with final.lib; {
      description = "Render mermaid diagrams as ASCII";
      homepage = "https://github.com/AlexanderGrooff/mermaid-ascii";
      license = licenses.mit;
      mainProgram = "mermaid-ascii";
    };
  };
}
