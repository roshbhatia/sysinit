_:

{
  stylix.targets.bat.enable = true;

  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };
}
