{
  inputs,
  system,
  ...
}:

final: _prev:
let
  # HACK: Pin crossplane-cli to specific nixpkgs revision
  # The unstable channel version has compatibility issues.
  # TODO: Remove when nixpkgs-unstable has crossplane-cli >= 1.17.1
  crossplane-1-17-1 =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/882842d2a908700540d206baa79efb922ac1c33d.tar.gz";
        sha256 = "105v2h9gpaxq6b5035xb10ykw9i3b3k1rwfq4s6inblphiz5yw7q";
      })
      {
        inherit system;
        inherit (final) config;
      };

  # HACK: Pin some packages to nixos-24.05 stable
  # These packages have issues in unstable:
  # - awscli2: Frequent breakage due to Python dependency updates
  # - fish: Shell stability is critical, prefer stable releases
  # - ollama: Model compatibility requires stable versioning
  # TODO: Revisit periodically and move to unstable when stable
  stable =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
        sha256 = "0zydsqiaz8qi4zd63zsb2gij2p614cgkcaisnk11wjy3nmiq0x1s";
      })
      {
        inherit system;
        inherit (final) config;
      };
in
{
  # Firefox addons from nur-combined
  firefox-addons = inputs.firefox-addons.packages.${system};
  nur = {
    repos = {
      rycee = {
        firefox-addons = inputs.firefox-addons.packages.${system};
      };
    };
  };

  # Pinned package versions
  inherit (crossplane-1-17-1) crossplane-cli;
  inherit (stable) awscli2;
  inherit (stable) fish;
  inherit (stable) ollama;

  # Custom font: IoskeleyMono - Iosevka configured to mimic Berkeley Mono
  ioskeleymono = final.stdenv.mkDerivation {
    pname = "ioskeleymono";
    version = "2025.10.09-6";
    src = final.fetchzip {
      url = "https://github.com/ahatem/IoskeleyMono/releases/download/2025.10.09-6/IoskeleyMono-Build.zip";
      hash = "sha256-ABnfxLMtY8E5KqJkrtIlPB4ML7CSFvjizCabv7i7SbU=";
      stripRoot = false;
    };
    installPhase = ''
      mkdir -p $out/share/fonts/opentype
      cp -r $src/IoskeleyMono/* $out/share/fonts/opentype/ 2>/dev/null || cp $src/*.otf $out/share/fonts/opentype/
    '';
  };
}
