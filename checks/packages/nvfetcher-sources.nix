{ pkgs }:
let
  inherit (pkgs) lib;
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
  declared = builtins.attrNames (fromTOML (builtins.readFile ../../nvfetcher.toml));
  generated = builtins.attrNames pkgs.nvfetcherSources;
  manifest = builtins.attrNames (builtins.fromJSON (builtins.readFile ../../_sources/generated.json));
in
assert lib.assertMsg (
  declared == generated && declared == manifest
) "nvfetcher output must contain every configured source";
nativeCheck {
  name = "nvfetcher-sources";
  commands = [
    [
      "nu"
      "--no-config-file"
      "${../../hack}/test-github-release-with-assets.nu"
    ]
  ];
}
