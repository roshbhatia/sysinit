{
  programs.nushell = {
    enable = true;
    loadSessionVariables = false;

    settings = {
      show_banner = false;
      edit_mode = "vi";
      cursor_shape = {
        vi_insert = "line";
        vi_normal = "block";
      };
    };

    extraConfig = ''
      use std/dirs
      use std/dirs shells-aliases *
    '';
  };
}
