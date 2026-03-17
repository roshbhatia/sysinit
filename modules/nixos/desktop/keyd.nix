# keyd — lightweight key remapping daemon
# Maps Super+key → Ctrl+key at the evdev level for macOS-like keybindings.
# Much simpler and more reliable than kanata for basic modifier remapping.
{ ... }:

{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          # When Super (Meta) is held with these keys, send Ctrl+key instead
          # Super alone and Super+non-listed keys pass through to sway
        };
        # Meta layer: activated when Super is held
        "meta" = {
          c = "C-c";      # copy
          v = "C-v";      # paste
          x = "C-x";      # cut
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
