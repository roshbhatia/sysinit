_final: prev:
let
  fullBuild = prev.komorebi-full.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ../patches/komorebi-appkit-notification-import.patch ];
  });
  binary =
    name:
    prev.runCommand "komorebi-${name}" { } ''
      mkdir -p "$out/bin"
      cp "${fullBuild}/bin/${name}" "$out/bin/${name}"
    '';
in
{
  komorebi-full = fullBuild;
  komorebi = binary "komorebi";
  komorebic = binary "komorebic";
  komorebi-bar = binary "komorebi-bar";
}
