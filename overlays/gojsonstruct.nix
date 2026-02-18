{ ... }:

final: _prev: {
  gojsonstruct = final.buildGoModule rec {
    pname = "gojsonstruct";
    version = "3.3.0";

    src = final.fetchFromGitHub {
      owner = "twpayne";
      repo = "go-jsonstruct";
      rev = "v${version}";
      hash = "sha256-mNZAezLKMrgnzsRikrZhmjTuF+B1ob5Bjh33voNsyCs=";
    };

    vendorHash = "sha256-BDZq3Pm+JmwfDWXQmwuxefVuhRrCb1DHLP+WdCJyieY=";

    subPackages = [ "cmd/gojsonstruct" ];

    meta = with final.lib; {
      description = "Generate Go structs from JSON";
      homepage = "https://github.com/twpayne/go-jsonstruct";
      license = licenses.mit;
      mainProgram = "gojsonstruct";
    };
  };
}
