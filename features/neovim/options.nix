{ lib, ... }:
{
  options.sysinit.neovim.configPath = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Optional editor checkout path; null uses the pinned source.";
  };
}
