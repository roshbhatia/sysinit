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

  cupcake-cli = inputs.cupcake.packages.${system}.cupcake-cli;

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
}
