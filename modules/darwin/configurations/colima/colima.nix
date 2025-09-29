{
  pkgs,
  ...
}:
let
  setupScript = pkgs.substituteAll {
    src = ./scripts/setup-certs.sh;
    isExecutable = true;
    colima = pkgs.colima;
  };
in
{
  launchd.user.agents = {
    colima = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.colima}/bin/colima"
          "start"
          "--cpu"
          "4"
          "--memory"
          "8"
          "--disk"
          "100"
          "--arch"
          "aarch64"
          "--runtime"
          "docker"
          "--vm-type"
          "vz"
          "--vz-rosetta"
          "--mount-type"
          "sshfs"
          "--activate"
          "--ssh-config"
          "--mount-inotify"
          "--network-address"
          "--dns"
          "1.1.1.1"
          "--dns"
          "1.0.0.1"
          "--save-config"
          "-V"
          "/tmp/colima:w"
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
