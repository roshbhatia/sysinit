{
  config,
  lib,
  pkgs,
  values,
  ...
}:

{
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };


}
