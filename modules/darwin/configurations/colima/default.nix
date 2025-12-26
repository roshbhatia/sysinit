{
  pkgs,
  values,
  ...
}:
{
  launchd.agents."colima" = {
    command = "${pkgs.colima}/bin/colima start --foreground --vz-rosetta --cpu 4 --memory 8 --ssh-port 22";
    serviceConfig = {
      Label = "com.colima.default";
      RunAtLoad = true;
      KeepAlive = true;

      StandardOutPath = "/tmp/colima.log";
      StandardErrorPath = "/tmp/colima.error.log";

      EnvironmentVariables = {
        PATH = "${pkgs.colima}/bin:${pkgs.docker}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        HOME = "/Users/${values.user.username}";
      };
    };
  };
}
