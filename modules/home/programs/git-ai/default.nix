{
  config,
  lib,
  pkgs,
  ...
}:
let
  command = [
    "${pkgs.git-ai}/bin/git-ai"
    "bg"
    "run"
  ];
  provider = pkgs.writeShellApplication {
    name = "changes-provider-git-ai";
    runtimeInputs = [
      pkgs.git-ai
      config.programs.git.package
    ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./changes-provider.py} "$@"
    '';
  };
  yamlFormat = pkgs.formats.yaml { };
in
{
  home.packages = [
    pkgs.git-ai
    provider
  ];

  xdg.configFile."changes/providers/git-ai/provider.yaml".source =
    yamlFormat.generate "git-ai-provider.yaml"
      {
        version = "provider/v1";
        name = "git-ai";
        description = "Read Git AI attribution and originating Traces session IDs";
        command = [ "${provider}/bin/changes-provider-git-ai" ];
        actions."changes.notes".description = "Read attribution without changing review notes";
        defaults.timeout = "60s";
      };

  home.file.".git-ai/config.json".text = builtins.toJSON {
    git_path = "${config.programs.git.package}/bin/git";
    disable_auto_updates = true;
    disable_version_checks = true;
    telemetry_oss = "off";
    prompt_storage = "local";
    feature_flags.daemon_log_upload = false;
  };

  programs.git.settings.trace2 = {
    eventTarget = "af_unix:stream:${config.home.homeDirectory}/.git-ai/internal/daemon/trace2.sock";
    eventNesting = 0;
  };

  launchd.agents.git-ai = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = command;
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/git-ai.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/git-ai.error.log";
    };
  };

  systemd.user.services.git-ai = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit.Description = "Git AI attribution daemon";
    Service = {
      ExecStart = lib.escapeShellArgs command;
      Restart = "always";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
