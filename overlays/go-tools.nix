# overlays/go-tools.nix
# Purpose: Go development tools not in nixpkgs.
{ ... }:

final: _prev: {
  go-enum = final.buildGoModule rec {
    pname = "go-enum";
    version = "0.6.0";

    src = final.fetchFromGitHub {
      owner = "abice";
      repo = "go-enum";
      rev = "v${version}";
      hash = "sha256-rKVMBzFSsPqFjxO0Kp80ccGJ5/3388DGuOoP+v/TMDM=";
    };

    vendorHash = "sha256-D5GIRyflPDMgJD/lwFX3kzXMpNMTqd6g/jL7qdrdBkU=";

    meta = with final.lib; {
      description = "An enum generator for Go";
      homepage = "https://github.com/abice/go-enum";
      license = licenses.mit;
      mainProgram = "go-enum";
    };
  };

  gomvp = final.buildGoModule rec {
    pname = "gomvp";
    version = "0.0.4";

    src = final.fetchFromGitHub {
      owner = "abenz1267";
      repo = "gomvp";
      rev = "v${version}";
      hash = "sha256-dXjI+nItJCAGKxyC9tX11hxWHCP+NgXtTYtm5+6dqDU=";
    };

    vendorHash = "sha256-OB8pkD7Y/lNJvVxPdPei48JMaAf+bgK1Na8G7bqlLak=";

    meta = with final.lib; {
      description = "Refactoring tool for moving Go packages";
      homepage = "https://github.com/abenz1267/gomvp";
      license = licenses.mit;
      mainProgram = "gomvp";
    };
  };

  json-to-struct = final.buildGoModule rec {
    pname = "json-to-struct";
    version = "unstable-2023-06-02";

    src = final.fetchFromGitHub {
      owner = "tmc";
      repo = "json-to-struct";
      rev = "340a931e614adf8e0af591cab1fed7a2ad3afe81";
      hash = "sha256-7zvWUVo0w+eXyNLP1mnoLMWnyfc3xQIMgK+eD/yCSeU=";
    };

    vendorHash = "sha256-2bS+KKrvCkPw6SJnrpaph/ijT0VHKO+pHbRCECKwxcs=";

    meta = with final.lib; {
      description = "Generate Go struct definitions from JSON";
      homepage = "https://github.com/tmc/json-to-struct";
      license = licenses.mit;
      mainProgram = "json-to-struct";
    };
  };

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
