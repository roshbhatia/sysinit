{
  lsp = {
    up = {
      command = [
        "up"
        "xpls"
        "serve"
      ];
      extensions = [ ".yaml" ];
    };
    systemd_lsp = {
      command = [ "systemd-lsp" ];
      extensions = [
        ".service"
        ".socket"
        ".timer"
        ".mount"
        ".target"
        ".path"
        ".slice"
        ".automount"
        ".swap"
        ".link"
        ".netdev"
        ".network"
        ".nspawn"
        ".override"
      ];
    };
  };
}
