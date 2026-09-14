{
  lib,
  pkgs,
  hostname,
  ...
}:
{
  config = lib.mkIf (hostname == "arrakis") {
    services.github-runners.sysinit = {
      enable = true;
      name = "arrakis-sysinit";
      url = "https://github.com/roshbhatia/sysinit";
      tokenFile = "/var/lib/secrets/github-runner-sysinit";
      replace = true;
      extraLabels = [
        "arrakis"
        "nix"
        "tailscale"
      ];
      extraPackages = with pkgs; [
        cachix
        curl
        jq
        openssh
        tailscale
      ];
      extraEnvironment.ACTIONS_RUNNER_HOOK_JOB_STARTED = pkgs.writeShellScript "sysinit-runner-job-guard" (
        builtins.readFile ./github-runner-guard.sh
      );
    };
    systemd.services.github-runner-sysinit = {
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
    };
  };
}
