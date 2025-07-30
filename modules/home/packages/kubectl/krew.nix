{
  lib,
  values,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.krewPackages = activation.mkPackageManager {
    name = "krew";
    basePackages = [
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
    ];
    additionalPackages = (values.krew.additionalPackages or [ ]);
    executableArguments = [
      "install"
      "--no-update-index"
    ];
    executableName = "krew";
  };
}
