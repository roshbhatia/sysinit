{ ... }:

final: _prev: {
  go-enum = final.buildGoModule rec {
    pname = "go-enum";
    version = "0.6.0";

    src = final.fetchFromGitHub {
      owner = "abice";
      repo = "go-enum";
      rev = "v${version}";
      hash = "sha256-Mt45Qz8l++bvBLKEpbX0m8iTkHDpsZtdYhhHUprQKY8=";
    };

    vendorHash = "sha256-D5GIRyflPDMgJD/lwFX3kzXMpNMTqd6g/jL7qdrdBkU=";

    meta = with final.lib; {
      description = "An enum generator for Go";
      homepage = "https://github.com/abice/go-enum";
      license = licenses.mit;
      mainProgram = "go-enum";
    };
  };
}
