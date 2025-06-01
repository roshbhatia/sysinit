{
  inputs,
  username,
  homeDirectory,
  overlay,
  ...
}:
{
  imports = [
    ./configurations
    ./packages
  ];
}
