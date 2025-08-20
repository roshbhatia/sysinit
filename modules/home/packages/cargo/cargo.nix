{
  config,
  lib,
  pkgs,
  values,
  utils,
  ...
}:

let
  cargoPackages = [
    "tree-sitter-cli"
  ]
  ++ (values.cargo.additionalPackages or [ ]);
in
{
  home.activation = {
    cargoPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      utils.sysinit.mkPackageManagerScript config "cargo" cargoPackages
    );

    eza = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Installing eza with vendored libgit2..."
      if [ -f "${pkgs.rustup}/bin/cargo" ]; then
        "${pkgs.rustup}/bin/cargo" install --locked --features vendored-libgit2 eza || {
          echo "Warning: Failed to install eza"
        }
        echo "Completed eza installation"
      else
        echo "Warning: cargo not available at ${pkgs.rustup}/bin/cargo, skipping eza installation"
      fi
    '';
  };
}
