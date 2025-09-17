{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  uvxPackages = [
    "hererocks"
    "git+https://github.com/chroma-core/chroma.git@0.6.3"
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
