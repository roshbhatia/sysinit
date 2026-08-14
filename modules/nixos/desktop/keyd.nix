_:

{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = { };
        "meta" = {
          c = "C-S-c";
          v = "C-S-v";
          x = "C-S-x";
          a = "C-a";
          z = "C-z";
          w = "C-w";
          n = "C-n";
          f = "C-f";
          t = "C-t";
          s = "C-s";
          r = "C-r";
          l = "C-l";
          p = "C-p";
        };
      };
    };
  };
}
