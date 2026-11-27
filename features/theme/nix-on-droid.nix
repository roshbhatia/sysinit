{ lib, ... }:

{
  terminal.colors = {
    background = "#fafafa";
    foreground = "#181818";
    cursor = "#181818";
  }
  // builtins.listToAttrs (
    lib.imap0 (index: value: lib.nameValuePair "color${toString index}" value) [
      "#181818"
      "#333333"
      "#444444"
      "#525252"
      "#3a3a3a"
      "#494949"
      "#5c5c5c"
      "#dddddd"
      "#626262"
      "#262626"
      "#373737"
      "#454545"
      "#303030"
      "#404040"
      "#505050"
      "#ffffff"
    ]
  );
}
