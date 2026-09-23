{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sysinit.storage.maintenance;
  home = config.home.homeDirectory;
  policy = pkgs.writeText "cache-maintenance.json" (
    builtins.toJSON [
      {
        name = "go-build";
        directory = "${home}/Library/Caches/go-build";
        max_bytes = 4 * 1024 * 1024 * 1024;
        command = [
          "${pkgs.go}/bin/go"
          "clean"
          "-cache"
        ];
        env.GOCACHE = "${home}/Library/Caches/go-build";
      }
      {
        name = "lima";
        directory = "${home}/Library/Caches/lima";
        max_bytes = 4 * 1024 * 1024 * 1024;
        command = [
          "${pkgs.lima}/bin/limactl"
          "prune"
        ];
      }
      {
        name = "uv";
        directory = "${config.xdg.cacheHome}/uv";
        max_bytes = 2 * 1024 * 1024 * 1024;
        command = [
          "${pkgs.uv}/bin/uv"
          "cache"
          "prune"
          "--cache-dir"
          "${config.xdg.cacheHome}/uv"
        ];
        env.UV_LOCK_TIMEOUT = "1";
      }
    ]
  );
  command = pkgs.writeShellApplication {
    name = "cache-maintain";
    text = ''exec ${pkgs.sysinit-gotools}/bin/cache-maintain --config ${policy} "$@"'';
  };
in
{
  options.sysinit.storage.maintenance.enable = lib.mkEnableOption "Daily native cache maintenance";
  config = lib.mkIf cfg.enable {
    home.packages = [ command ];
    launchd.agents.cache-maintenance = {
      enable = true;
      config = {
        ProgramArguments = [
          "${command}/bin/cache-maintain"
          "--apply"
          "--report"
          "${config.xdg.stateHome}/sysinit/cache-maintenance.json"
        ];
        RunAtLoad = true;
        StartInterval = 86400;
        ProcessType = "Background";
        LowPriorityIO = true;
      };
    };
  };
}
