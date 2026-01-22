{
  inputs,
  system,
  ...
}:

final: _prev:
let
  crossplane-1-17-1 =
    import
      (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/882842d2a908700540d206baa79efb922ac1c33d.tar.gz";
        sha256 = "105v2h9gpaxq6b5035xb10ykw9i3b3k1rwfq4s6inblphiz5yw7q";
      })
      {
        inherit system;
        inherit (final) config;
      };

  stable =
    import
      (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
        sha256 = "0zydsqiaz8qi4zd63zsb2gij2p614cgkcaisnk11wjy3nmiq0x1s";
      })
      {
        inherit system;
        inherit (final) config;
      };
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
  python313 = _prev.python313.override {
    packageOverrides = _pythonFinal: pythonPrev: {
      setproctitle = pythonPrev.setproctitle.overridePythonAttrs (_old: {
        doCheck = false;
      });
      accelerate = pythonPrev.accelerate.overridePythonAttrs (_old: {
        doCheck = false;
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
  inherit (stable) awscli2;
  inherit (stable) ollama;

  neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${system}.default;

  bv = final.buildGoModule {
    pname = "bv";
    version = "0.11.3";
    src = inputs.bv;
    vendorHash = null; # Uses vendored dependencies in repo
    subPackages = [ "cmd/bv" ];
    ldflags = [
      "-s"
      "-w"
    ];
    meta = with final.lib; {
      description = "Terminal UI for viewing beads files";
      homepage = "https://github.com/Dicklesworthstone/beads_viewer";
      license = licenses.mit;
      mainProgram = "bv";
    };
  };

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
