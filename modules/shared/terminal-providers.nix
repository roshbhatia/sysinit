{
  config,
  inputs,
  lib,
  pkgs,
}:
let
  sessionTree = inputs.sysinit-wezterm.inputs.session-tree;
  runner = pkgs.writeShellApplication {
    name = "terminal-picker-call";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      exec ${lib.getExe pkgs.nushell} --no-config-file ${sessionTree}/scripts/picker-call.nu "$@"
    '';
  };
in
{
  command = [ (lib.getExe runner) ];
  providers = [
    {
      name = "tether";
      key = "@";
      manifest = "${pkgs.tether-picker}/share/wezterm/providers/tether.json";
    }
    {
      name = "seshy";
      key = "$";
      manifest = "${pkgs.seshy-picker}/share/wezterm/providers/seshy.json";
    }
    {
      name = "zoxide";
      key = "%";
      manifest = "${pkgs.zoxide-picker}/share/wezterm/providers/zoxide.json";
    }
  ]
  ++ lib.optionals (config.sysinit.queue.enable or false) [
    {
      name = "tq";
      palette_title = "Queue: browse attempts";
      manifest = "${pkgs.tq-picker}/share/wezterm/providers/tq.json";
    }
  ];
}
