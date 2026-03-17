_:

{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = { };
        "meta" = {
          c = "C-S-c"; # copy (Ctrl+Shift+C works in wezterm + GTK apps)
          v = "C-S-v"; # paste (Ctrl+Shift+V works in wezterm + GTK apps)
          x = "C-S-x"; # cut
          a = "C-a"; # select all
          z = "C-z"; # undo
          w = "C-w"; # close tab
          n = "C-n"; # new
          f = "C-f"; # find
          t = "C-t"; # new tab
          s = "C-s"; # save
          r = "C-r"; # reload
          l = "C-l"; # address bar
          p = "C-p"; # print
        };
      };
    };
  };
}
