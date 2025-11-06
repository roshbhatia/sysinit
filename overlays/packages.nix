{
  inputs,
  system,
  ...
}:

final: prev:
let
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    inherit (final) config;
  };

  crossplane-1-17-1 =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/882842d2a908700540d206baa79efb922ac1c33d.tar.gz";
      })
      {
        inherit system;
        inherit (final) config;
      };

  stable-nixpkgs =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
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
  inherit (unstable) neovim-unwrapped;
  inherit (unstable) nix-your-shell;
  inherit (unstable) nushell;
  inherit (unstable) sbarlua;
  inherit (crossplane-1-17-1) crossplane-cli;
  inherit (stable-nixpkgs) awscli2;

  vscode-extensions = prev.vscode-extensions // {
    rust-lang = prev.vscode-extensions.rust-lang // {
      inherit (stable-nixpkgs.vscode-extensions.rust-lang) rust-analyzer;
    };
  };
}
