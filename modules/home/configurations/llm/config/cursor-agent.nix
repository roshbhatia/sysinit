{
  ...
}:
{
  home.file."cursor/cli-config.json" = {
    text = builtins.toJSON {
      version = 1;

      permissions = {
        allow = [ "Shell(ls)" ];
        deny = [ ];
      };

      editor = {
        vimMode = true;
      };

      network = {
        useHttp1ForAgent = true;
      };
    };

    force = true;
  };
}
