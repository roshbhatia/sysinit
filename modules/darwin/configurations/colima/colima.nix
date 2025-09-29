{
  pkgs,
  ...
}:
let
  colimaConfig = ./configs/colima.yaml;

  setupScript = pkgs.replaceVars ./scripts/setup-certs.sh {
    colima = "${pkgs.colima}";
  };
in
{
  launchd.user.agents = {
    colima = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.colima}/bin/colima"
          "start"
          "--config"
          "${colimaConfig}"
        ];
        EnvironmentVariables = {
          PATH = "${pkgs.docker}/bin:${pkgs.docker-compose}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        RunAtLoad = true;
        KeepAlive = false;
        StandardOutPath = "/tmp/colima.log";
        StandardErrorPath = "/tmp/colima.error.log";
        ProcessType = "Background";
      };
    };

    colima-setup = {
      serviceConfig = {
        ProgramArguments = [ "${setupScript}" ];
        EnvironmentVariables = {
          PATH = "${pkgs.docker}/bin:${pkgs.colima}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        RunAtLoad = true;
        KeepAlive = false;
        StandardOutPath = "/tmp/colima-setup.log";
        StandardErrorPath = "/tmp/colima-setup.error.log";
        ProcessType = "Background";
        StartInterval = 60;
      };
    };

    colima-cert-watcher = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.fswatch}/bin/fswatch"
          "-o"
          "/System/Library/Keychains/SystemRootCertificates.keychain"
          "--event"
          "Updated"
        ];
        EnvironmentVariables = {
          PATH = "${pkgs.docker}/bin:${pkgs.colima}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/colima-cert-watcher.log";
        StandardErrorPath = "/tmp/colima-cert-watcher.error.log";
        ProcessType = "Background";
      };
    };

    colima-config-watcher = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.fswatch}/bin/fswatch"
          "-o"
          "${colimaConfig}"
          "--event"
          "Updated"
        ];
        EnvironmentVariables = {
          PATH = "${pkgs.docker}/bin:${pkgs.colima}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/colima-config-watcher.log";
        StandardErrorPath = "/tmp/colima-config-watcher.error.log";
        ProcessType = "Background";
      };
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "setup-colima-certs" (builtins.readFile "${setupScript}"))
  ];
}
