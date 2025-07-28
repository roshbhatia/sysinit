{
  ...
}:
{
  programs.nushell = {
    enable = true;
    configFile.text = builtins.readFile ./config.nu;
    envFile.text = builtins.readFile ./env.nu;
  };
}
