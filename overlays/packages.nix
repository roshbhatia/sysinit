{
  inputs,
  system,
  ...
}:

final: _prev:
let
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config = final.config;
  };

  crossplane-1-17-1 =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/882842d2a908700540d206baa79efb922ac1c33d.tar.gz";
      })
      {
        inherit system;
        config = final.config;
      };

  # Pin dotnet and awscli2 to stable versions that build successfully
  stable-nixpkgs =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
      })
      {
        inherit system;
        config = final.config;
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
  neovim-unwrapped = unstable.neovim-unwrapped;
  nix-your-shell = unstable.nix-your-shell;
  nushell = unstable.nushell;
  sbarlua = unstable.sbarlua;
  crossplane-cli = crossplane-1-17-1.crossplane-cli;

  # Override broken packages with stable versions
  dotnet-sdk_8 = stable-nixpkgs.dotnet-sdk_8;
  awscli2 = stable-nixpkgs.awscli2;
}
