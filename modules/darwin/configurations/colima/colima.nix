{
  pkgs,
  ...
}:
{
  launchd.user.agents.colima = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.colima}/bin/colima"
        "start"
        "--cpu"
        "6"
        "--memory"
        "12"
        "--disk"
        "50"
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
        "--save-config"
        "-V"
        "/usr/local/share/ca-certificates:w"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/tmp/colima.log";
      StandardErrorPath = "/tmp/colima.error.log";
      ProcessType = "Background";
    };
  };
}
