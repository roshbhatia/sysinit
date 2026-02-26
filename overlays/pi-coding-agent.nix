{ ... }:

final: _prev:
let
  version = "0.55.1";
in
{
  pi-coding-agent = final.stdenvNoCC.mkDerivation {
    pname = "pi-coding-agent";
    inherit version;

    src = final.fetchurl {
      url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
      hash = "sha256-+gUj3BPFAmxqkeNcYLg1J1iXAjEdWpByqX4Ixyc4NmE=";
    };

    sourceRoot = "package";

    nativeBuildInputs = [
      final.nodejs
      final.makeWrapper
    ];

    configurePhase = "true";
    buildPhase = "true";

    installPhase = ''
      runHook preInstall
      
      mkdir -p $out/lib/node_modules/@mariozechner/pi-coding-agent $out/bin
      cp -r . $out/lib/node_modules/@mariozechner/pi-coding-agent/
      
      # Install dependencies
      cd $out/lib/node_modules/@mariozechner/pi-coding-agent
      ${final.nodejs}/bin/npm install --legacy-peer-deps --production
      
      # Create wrapper
      makeWrapper ${final.nodejs}/bin/node $out/bin/pi \
        --add-flags "$out/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js"
      
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Coding agent CLI with read, bash, edit, write tools and session management";
      homepage = "https://github.com/badlogic/pi-mono";
      license = licenses.mit;
      mainProgram = "pi";
    };
  };
}
