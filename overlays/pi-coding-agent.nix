_:

final: _prev: {
  pi-coding-agent = final.buildNpmPackage {
    pname = "pi-coding-agent";
    version = "0.55.4";

    src = final.fetchurl {
      url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-0.55.4.tgz";
      hash = "sha256-GnzPe1QJcFhpLZVlREvgRu/zh3GTXxeK/o58DdQ6QiI=";
    };

    postPatch = ''
      cp ${./pi-coding-agent-package-lock.json} package-lock.json
    '';

    npmDepsHash = final.fakeHash;
    dontNpmBuild = true;

    meta = with final.lib; {
      description = "Coding agent CLI with read, bash, edit, write tools and session management";
      homepage = "https://github.com/badlogic/pi-mono";
      license = licenses.mit;
      mainProgram = "pi";
    };
  };
}
