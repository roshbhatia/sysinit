{
  inputs,
  system,
  ...
}:

final: _prev:
let
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
  firefox-addons = inputs.firefox-addons.packages.${system};
  nur = {
    repos = {
      rycee = {
        firefox-addons = inputs.firefox-addons.packages.${system};
      };
    };
  };

  inherit (crossplane-1-17-1) crossplane-cli;
  inherit (stable) awscli2;
  inherit (stable) fish;
  inherit (stable) ollama;

  niri = _prev.niri.overrideAttrs (_: {
    doCheck = false;
  });
}
