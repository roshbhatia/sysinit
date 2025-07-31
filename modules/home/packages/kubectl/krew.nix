{
  lib,
  values,
  utils,
  ...
}:

let
  krewPackages = [
    "argo-apps-viz"
    "blame"
    "bulk-action"
    "commander"
    "confirm"
    "ctx"
    "debug-shell"
    "history"
    "pod-inspect"
    "pod-lens"
    "pod-logs"
    "pod-shell"
    "pods-on"
    "status"
    "tail"
  ]
  ++ (values.krew.additionalPackages or [ ]);
in
{
  home.activation.krewPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (utils.sysinit.mkPackageManagerScript "kubectl" krewPackages);
}
