{ config, pkgs, ... }:
{
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    config = {
      news.version = "3.5.0";
      uda = {
        repo = {
          type = "string";
          label = "Repository";
        };
        agent = {
          type = "string";
          label = "Agent session";
        };
      };
    };
  };
  home.sessionVariables.TASKRC = "${config.xdg.configHome}/task/taskrc";
}
