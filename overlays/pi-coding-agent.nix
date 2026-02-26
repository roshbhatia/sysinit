{ ... }:

final: _prev:
let
  version = "0.55.1";

  src = final.fetchFromGitHub {
    owner = "badlogic";
    repo = "pi-mono";
    rev = "v${version}";
    hash = "sha256-86+Ef/tJ4XuOWxHFKotZQTXEnwZW7Fc8nqbyLheqlaw=";
  };

  npmDeps = final.fetchNpmDeps {
    pname = "pi-coding-agent";
    inherit version;
    src = "${src}/packages/coding-agent";
    prePatch = ''
      cp ${src}/package-lock.json .
    '';
  };
in
{
  pi-coding-agent = final.buildNpmPackage {
    pname = "pi-coding-agent";
    inherit version src npmDeps;

    sourceRoot = "source/packages/coding-agent";

    prePatch = ''
      cp ../../../package-lock.json .
    '';

    postInstall = ''
      makeWrapper ${final.nodejs}/bin/node $out/bin/pi \
        --add-flags "$out/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js"
    '';

    nativeBuildInputs = [ final.makeWrapper ];

    meta = with final.lib; {
      description = "Coding agent CLI with read, bash, edit, write tools and session management";
      homepage = "https://github.com/badlogic/pi-mono";
      license = licenses.mit;
      mainProgram = "pi";
    };
  };
}
