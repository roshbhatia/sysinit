# This module ensures lib.hm is available to all home-manager modules
{
  inputs,
  lib,
  ...
}:

{
  _module.args.lib = lib // {
    hm = inputs.home-manager.lib.hm;
  };
}
