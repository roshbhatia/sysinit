{
  ...
}:
{
  xdg.configFile."cursor/cli-config.json" = {
    text = builtins.toJSON {
      version = 1;

      permissions = {
        allow = [ "Shell(ls)" ];
        deny = [ ];
      };

      editor = {
        vimMode = true;
      };
    };
    force = true;
  };
}
