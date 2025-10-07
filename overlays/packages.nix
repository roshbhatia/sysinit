{
  inputs,
  system,
  ...
}:

final: prev:
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
  awscli2 = stable-nixpkgs.awscli2;

  # Override vscode-extensions to use stable rust-analyzer that doesn't depend on broken dotnet
  vscode-extensions = prev.vscode-extensions // {
    rust-lang = prev.vscode-extensions.rust-lang // {
      rust-analyzer = stable-nixpkgs.vscode-extensions.rust-lang.rust-analyzer;
    };
  };
}
