# keyd — lightweight key remapping daemon
# Maps Super+key → Ctrl+key at the evdev level for macOS-like keybindings.
# For copy/paste/cut, maps to Ctrl+Shift+C/V/X which works in both
# terminals (wezterm) and GUI apps (Firefox, etc.).
{ ... }:

{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = { };
        # Meta layer: activated when Super is held
        "meta" = {
          # Copy/paste/cut: Ctrl+Shift variants work in both terminal and GUI
          c = "C-S-c";    # copy (Ctrl+Shift+C works in wezterm + GTK apps)
          v = "C-S-v";    # paste (Ctrl+Shift+V works in wezterm + GTK apps)
          x = "C-S-x";    # cut

          # These only need Ctrl (no terminal conflict)
          a = "C-a";      # select all
          z = "C-z";      # undo
          w = "C-w";      # close tab
          n = "C-n";      # new
          f = "C-f";      # find
          t = "C-t";      # new tab
          s = "C-s";      # save
          r = "C-r";      # reload
          l = "C-l";      # address bar
          p = "C-p";      # print
        };
      };
    };
  };
}
