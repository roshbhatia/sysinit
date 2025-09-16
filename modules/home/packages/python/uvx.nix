{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  uvxPackages = [
    "chromadb"
    "hererocks"
    "https://github.com/github/spec-kit.git"
    "vectorcode[lsp,mcp]"
  ]
  ++ values.uvx.additionalPackages;
in
{
  home.activation.uvxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "uv" uvxPackages
  );
}
