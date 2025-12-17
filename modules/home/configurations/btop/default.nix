_:

{
  stylix.targets.btop.enable = true;

  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
      force_tty = true;
      theme_background = false;
      shown_boxes = "cpu proc";
    };
  };
}
