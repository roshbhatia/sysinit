{
  lib,
  values,
  ...
}:

{
  programs.helix = {
    enable = true;
    settings = {
      editor = {
        line-number = "relative";

        cursor-shape = {
          insert = "bar";
          select = "underline";
        };

        file-picker = {
          hidden = false;
        };
      };
    };
  };
}
