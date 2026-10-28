{
  lib,
  pkgs,
  home,
}:
let
  settings = pkgs.sysinit.writeJSON "atuin-settings.json" home.programs.atuin.settings;
  nushellLib = import ../modules/home/programs/nushell/lib.nix { inherit lib; };
  nushellInit = pkgs.runCommand "atuin-check-init.nu" { } ''
    export HOME="$TMPDIR"
    ${lib.getExe pkgs.atuin} init nu ${lib.escapeShellArgs home.programs.atuin.flags} > "$out"
  '';
  nushellConfig = pkgs.writeText "atuin-check-config.nu" ''
    ${nushellLib.completers pkgs}
    $env.FZF_CTRL_R_COMMAND = ""
    source ${home.programs.fzf.package}/share/fzf/key-bindings.nu
    source ${home.programs.fzf.package}/share/fzf/completion.nu
    source ${nushellInit}
    source ${../modules/home/programs/nushell/atuin-prompt.nu}
    $env.PROMPT_COMMAND = {|| "original-prompt " }
    $env.PROMPT_INDICATOR_VI_INSERT = ": "
    $env.PROMPT_COMMAND_RIGHT = ""
    $env.config.edit_mode = "vi"
    $env.config.show_banner = false
    $env.config.keybindings = ($env.config.keybindings | append {
      name: capture_buffer
      modifier: control
      keycode: char_x
      mode: [emacs vi_normal vi_insert]
      event: {send: executehostcommand, cmd: 'commandline | save --force $env.ATUIN_TEST_BUFFER'}
    })
  '';
in
assert home.programs.atuin.enable;
assert home.programs.atuin.daemon.enable;
assert home.programs.fzf.historyWidget.command == "";
assert builtins.all (shell: home.programs.atuin.${"enable${shell}Integration"}) [
  "Bash"
  "Fish"
  "Nushell"
];
pkgs.runCommand "atuin-local-history-and-threads"
  {
    nativeBuildInputs = [
      pkgs.atuin
      pkgs.codex
      pkgs.nushell
      pkgs.git
      (pkgs.python3.withPackages (ps: [
        ps.tomlkit
        ps.pyte
      ]))
    ];
  }
  ''
    python3 ${./atuin.py} ${settings} ${../modules/home/programs/nushell/agent-threads.nu}
    python3 ${./atuin-nushell.py} ${settings} ${nushellConfig}
    export HOME="$TMPDIR/nu-home"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$HOME"
    nu --config ${nushellConfig} -c '
      let history = ($env.config.keybindings | where modifier == control and keycode == char_r)
      for mode in [emacs vi_normal vi_insert] {
        let binding = ($history | where {|binding| $mode in $binding.mode} | last)
        if $binding.name != $"atuin-($mode)" {
          error make {msg: $"Atuin does not own Ctrl-R in ($mode): ($binding)"}
        }
      }
      let place = ("git --ver" | commandline complete --input | get place)
      let completion = (do $env.config.completions.external.completer $place)
      if not ($completion | any {|item| $item.value == "--version"}) {
        error make {msg: "Atuin displaced the existing completion chain"}
      }
    '
    touch "$out"
  ''
