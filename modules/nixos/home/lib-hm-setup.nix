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
