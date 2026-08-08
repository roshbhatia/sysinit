final: _prev:
let
  inherit (final.nvfetcherSources.tinycast) version src;
in
{
  # tinycast — native macOS launcher, hotkey daemon, and clipboard history. Replaces
  # the raycast cask, so the last GUI-only brew dependency in this repo goes away.
  #
  # Not in nixpkgs, and a source build is not possible here: upstream needs Xcode 26
  # and XcodeGen with no Package.swift, so the dmg is repacked instead.
  #
  # undmg cannot read this image — it is APFS, not HFS, and fails with
  # "only HFS file systems are supported". 7zz handles it; the image root holds
  # Tinycast.app next to a dangling /Applications symlink that must not be copied.
  #
  # The app is self-signed with no notarization, so macOS keys the Accessibility
  # grant partly on path: expect a re-prompt after each version bump moves the
  # store path.
  tinycast = final.stdenvNoCC.mkDerivation {
    pname = "tinycast";
    inherit version src;

    nativeBuildInputs = [ final._7zz ];

    unpackPhase = ''
      runHook preUnpack
      7zz x "$src" -o$PWD
      runHook postUnpack
    '';

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications
      cp -R Tinycast.app $out/Applications/
      runHook postInstall
    '';

    # A self-signed bundle has no slack for a rewritten Mach-O: stripping voids the
    # signature the Accessibility grant is pinned to.
    dontFixup = true;

    meta = with final.lib; {
      description = "Native macOS launcher, hotkeys, clipboard history, and snippets";
      homepage = "https://github.com/abue-ammar/tinycast";
      license = licenses.agpl3Plus;
      platforms = platforms.darwin;
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
    };
  };
}
