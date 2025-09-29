{
  pkgs,
  ...
}:
let
  colimaConfig = ./configs/colima.yaml;

  colimaManager = pkgs.replaceVars ./scripts/setup-certs.sh {
    colima = "${pkgs.colima}";
    colimaConfig = "${colimaConfig}";
  };
in
{
  launchd.user.agents = {
    colima-manager = {
      serviceConfig = {
        ProgramArguments = [ "${colimaManager}" "monitor" ];
        EnvironmentVariables = {
          PATH = "${pkgs.docker}/bin:${pkgs.colima}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/colima-manager.log";
        StandardErrorPath = "/tmp/colima-manager.error.log";
        ProcessType = "Background";
        StartInterval = 30;
      };
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "colima-manager" (builtins.readFile "${colimaManager}"))
  ];
}
