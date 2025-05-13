{
  pkgs,
  lib,
  config,
  userConfig ? { },
  ...
}:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in
{
  home.activation.krewPackages = activationUtils.mkPackageManager {
    name = "krew";
    basePackages = [
      "argo-apps-viz"
      "bulk-action"
      "commander"
      "confirm"
      "ctx"
      "debug-shell"
      "history"
      "pod-dive"
      "pod-inspect"
      "pod-lens"
      "pod-logs"
      "pod-shell"
      "podevents"
      "pods-on"
      "status"
      "strace"
      "tail"
      "warp"
    ];
    additionalPackages =
      if userConfig ? krewPackages && userConfig.krew ? additionalPackages then
        userConfig.krew.additionalPackages
      else
        [ ];
    executableArguments = [
      "krew"
      "install"
    ];
    executableName = "kubectl";
  };
}
