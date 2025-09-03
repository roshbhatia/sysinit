{ config, ... }:

{
  programs.jrnl = {
    enable = true;
    settings = {
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
          journal = "${config.home.homeDirectory}/github/work/${config.user.username}_nike/notes/jrnl";
          display_format = "markdown";
        };
      };
      linewrap = 79;
      tagsymbols = "#@";
      template = false;
      timeformat = "%F %r";
      version = "v4.2.1";
    };
  };
}
