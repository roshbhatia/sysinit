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
      final.makeWrapper
    ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/pi-coding-agent $out/bin
      cp -r . $out/lib/pi-coding-agent/
      makeWrapper ${final.nodejs}/bin/node $out/bin/pi \
        --add-flags "$out/lib/pi-coding-agent/dist/cli.js"
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
