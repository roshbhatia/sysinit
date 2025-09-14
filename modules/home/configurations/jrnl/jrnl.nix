{
  lib,
  pkgs,
  config,
  values,
  ...
}:

let
  workGithubUser =
    if (values.git.workGithubUser or null != null) then values.git.workGithubUser else values.git.githubUser;

  jrnlConfig = {
    colors = {
      body = "none";
      date = "black";
      tags = "yellow";
      title = "cyan";
    };
    default_hour = 9;
    default_minute = 0;
    editor = "nvim";
    encrypt = false;
    highlight = true;
    indent_character = "|";
    journals = {
      default = {
        journal = "${config.home.homeDirectory}/jrnl";
        display_format = "markdown";
      };
      work = {
        journal = "${config.home.homeDirectory}/github/work/${workGithubUser}/notes/jrnl";
        display_format = "markdown";
      };
    };
    linewrap = 79;
    tagsymbols = "#@";
    template = false;
    timeformat = "%F %r";
    version = "v4.2.1";
  };

  jrnlYaml = pkgs.writeText "config.yaml" (lib.generators.toYAML { } jrnlConfig);
in
{
  xdg.configFile."jrnl/config.yaml" = {
    source = jrnlYaml;
    force = true;
  };
}
