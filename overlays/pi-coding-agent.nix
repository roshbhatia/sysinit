{ ... }:

final: _prev:
let
  version = "0.55.1";
in
{
  pi-coding-agent = final.buildNpmPackage {
    pname = "pi-coding-agent";
    inherit version;

    src = final.fetchurl {
      url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
      hash = "sha256-+gUj3BPFAmxqkeNcYLg1J1iXAjEdWpByqX4Ixyc4NmE=";
    };

    npmDepsHash = "sha256-5FEhLKVlB5JHSR8Zr6bzrPUJBYeFCfZTp/0qYXq8HGU=";

    postInstall = ''
      makeWrapper ${final.nodejs}/bin/node $out/bin/pi \
        --add-flags "$out/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js"
    '';

    nativeBuildInputs = [ final.makeWrapper ];

    meta = with final.lib; {
      description = "Coding agent CLI with read, bash, edit, write tools and session management";
      homepage = "https://github.com/mariozechner/pi";
      license = licenses.mit;
      mainProgram = "pi";
    };
  };
}
