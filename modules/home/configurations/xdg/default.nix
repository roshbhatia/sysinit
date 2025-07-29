{
  config,
  ...
}:
{
  imports = [
    ./xdg.nix
    {
      inherit
        config
        ;
    }
  ];
}

