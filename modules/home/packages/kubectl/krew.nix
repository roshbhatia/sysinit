{
  lib,
  userConfig ? { },
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
    additionalPackages = (userConfig.krew.additionalPackages or [ ]);
    executableArguments = [
      "krew"
      "install"
    ];
    executableName = "kubectl";
  };
}
