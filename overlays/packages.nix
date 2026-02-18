{
  inputs,
  system,
  ...
}:

final: _prev:
let
  crossplane-1-17-1 = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/882842d2a908700540d206baa79efb922ac1c33d.tar.gz";
    sha256 = "105v2h9gpaxq6b5035xb10ykw9i3b3k1rwfq4s6inblphiz5yw7q";
  }) { inherit system; };

in
{
  firefox-addons = inputs.firefox-addons.packages.${system};
  nur = {
    repos = {
      rycee = {
        firefox-addons = inputs.firefox-addons.packages.${system};
      };
      inherit (inputs.nur.legacyPackages.${system}.repos) charmbracelet;
    };
  };

  # Fix setproctitle and accelerate test failures on macOS with Python 3.13
  # accelerate tests fail with Trace/BPT trap during pytest on darwin
  # aiohttp has flaky performance tests (test_regex_performance)
  # future-1.0.0 not yet marked as compatible with Python 3.13
  python313 = _prev.python313.override {
    packageOverrides = _pythonFinal: pythonPrev: {
      setproctitle = pythonPrev.setproctitle.overridePythonAttrs (_old: {
        doCheck = false;
      });
      accelerate = pythonPrev.accelerate.overridePythonAttrs (_old: {
        doCheck = false;
      });
      aiohttp = pythonPrev.aiohttp.overridePythonAttrs (_old: {
        doCheck = false;
      });
      future = pythonPrev.future.overridePythonAttrs (_old: {
        disabled = false;
      });
    };
  };

  python311 = _prev.python311.override {
    packageOverrides = _pythonFinal: pythonPrev: {
      setproctitle = pythonPrev.setproctitle.overridePythonAttrs (_old: {
        doCheck = false;
      });
      accelerate = pythonPrev.accelerate.overridePythonAttrs (_old: {
        doCheck = false;
      });
    };
  };

  karabiner-elements = _prev.karabiner-elements.overrideAttrs (old: {
    version = "14.13.0";
    src = _prev.fetchurl {
      inherit (old.src) url;
      hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
    };
  });

  inherit (crossplane-1-17-1) crossplane-cli;

  neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${system}.default;

  kubernetes-zeitgeist = final.buildGoModule rec {
    pname = "kubernetes-zeitgeist";
    version = "0.5.3";

    src = final.fetchFromGitHub {
      owner = "kubernetes-sigs";
      repo = "zeitgeist";
      rev = "v${version}";
      sha256 = "sha256-8vVqX6V0IMJk4GTksWEB88gwpG0Bp/LUI+LOcAQB1Gw=";
    };

    vendorHash = "sha256-E7ntN/BqDzgj9nJ7rKMDq8EBOvbvKQxQRI3/4mvkHQM=";

    subPackages = [ "." ];

    ldflags = [
      "-s"
      "-w"
      "-X=sigs.k8s.io/zeitgeist/pkg/version.version=${version}"
    ];

    meta = with final.lib; {
      description = "Language-agnostic dependency checker for Kubernetes projects";
      homepage = "https://github.com/kubernetes-sigs/zeitgeist";
      license = licenses.asl20;
      maintainers = [ ];
      mainProgram = "zeitgeist";
    };
  };

  # Fix OPA 1.13.1 test failures in v1/server package
  # Tests reference undefined fixture functions
  open-policy-agent = _prev.open-policy-agent.overrideAttrs (_old: {
    doCheck = false;
  });

  # Go development tools
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
