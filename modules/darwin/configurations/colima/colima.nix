{
  pkgs,
  ...
}:
let
  # Configuration file
  colimaConfig = ./configs/colima.yaml;

  # Certificate setup script with proper path substitution
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
        RunAtLoad = false;
        KeepAlive = false;
        StandardOutPath = "/tmp/colima-setup.log";
        StandardErrorPath = "/tmp/colima-setup.error.log";
        ProcessType = "Background";
        StartInterval = 30;
      };
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "setup-colima-certs" (builtins.readFile "${setupScript}"))
  ];
}
