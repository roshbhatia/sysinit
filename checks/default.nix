{
  pkgs,
  homeManagerLib,
  homeConfigurations,
  darwinConfigurations,
  nixosConfigurations,
  ...
}:
let
  nuFunctions = pkgs.writeText "sysinit-functions.nu" (
    builtins.replaceStrings
      [
        "@seshySessions@"
        "@timeout@"
      ]
      [
        "/tmp/seshy-sessions"
        "${pkgs.coreutils}/bin/timeout"
      ]
      (builtins.readFile ../features/nushell/functions.nu)
  );
in
(import ./agents {
  inherit
    pkgs
    homeConfigurations
    darwinConfigurations
    nixosConfigurations
    ;
})
// (import ./desktop {
  inherit
    pkgs
    homeConfigurations
    darwinConfigurations
    nixosConfigurations
    ;
})
// (import ./editor { inherit pkgs homeManagerLib; })
// (import ./host { inherit pkgs darwinConfigurations nixosConfigurations; })
// {
  managed-file-cache = import ./managed-files/managed-file-cache.nix { inherit pkgs; };
}
// (import ./packages { inherit pkgs; })
// (import ./shell {
  inherit
    pkgs
    homeConfigurations
    darwinConfigurations
    nixosConfigurations
    nuFunctions
    ;
})
// (import ./workflows { inherit pkgs nuFunctions; })
