{
  ...
}:
{
  imports = [
    ./osx
    ./aerospace
    (import ./borders { inherit lib values pkgs; })
    (import ./sketchybar { inherit lib values pkgs; })
  ];
}
