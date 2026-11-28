{
  config,
  lib,
  pkgs,
  ...
}:
let
  engine = import ./managed-file.nix { inherit lib; };
  files = config.sysinit.managedFiles;
  reconciler = engine.mkReconciler { inherit pkgs files; };
in
{
  imports = [ ./options.nix ];

  home.activation.llmManagedFiles = lib.mkIf (files != { }) (
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${lib.getExe reconciler} || \
        echo "managed-file: one or more configs were left untouched; see above. Activation continued." >&2
    ''
  );
  home.packages = [ (engine.mkCapture { inherit pkgs files; }) ];
}
