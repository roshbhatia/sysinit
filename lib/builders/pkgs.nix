{
  lib,
  nixpkgs,
  inputs,
}:

{
  mkPkgs =
    {
      system,
      overlays ? [ ],
    }:
    import nixpkgs {
      inherit system overlays;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
        allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "_1password-gui"
            # Antigravity CLI (`agy`) — the Gemini-family harness in llm/.
            "antigravity-cli"
            # boldsoftware/meat ships no LICENSE (upstream #2), so it is unfree by
            # default copyright rather than by an explicit non-free grant.
            "meat"
          ];
        # Obsidian (arrakis desktop) bundles an EOL Electron; the pinned version
        # churns on nixpkgs-unstable, so match by name rather than exact version.
        # getName strips the version, so this is "electron", not "electron-40.x".
        allowInsecurePredicate = pkg: lib.hasPrefix "electron" (lib.getName pkg);
      };
    };

  mkUtils = { system, pkgs }: import ../../modules/lib { inherit lib pkgs system; };

  mkOverlays = _system: import ../../overlays/default.nix { inherit inputs; };
}
