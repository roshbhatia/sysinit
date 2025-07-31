{
  lib,
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
    cargoPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (utils.sysinit.mkPackageManagerScript "cargo" cargoPackages);

    eza = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Installing eza with vendored libgit2..."
      if command -v cargo >/dev/null 2>&1; then
        cargo install --locked --features vendored-libgit2 eza || {
          echo "Warning: Failed to install eza"
        }
        echo "Completed eza installation"
      else
        echo "Warning: cargo not available, skipping eza installation"
      fi
    '';
  };
}
