{ pkgs, ... }:

{
  programs.bash.enable = true;

  xdg.dataFile = {
    "bash-completion/completions/ask.bash".source =
      "${pkgs.ask}/share/bash-completion/completions/ask.bash";
    "bash-completion/completions/changes.bash".source =
      "${pkgs.changes}/share/bash-completion/completions/changes.bash";
    "bash-completion/completions/orc".source = "${pkgs.orc-cli}/share/bash-completion/completions/orc";
    "bash-completion/completions/traces.bash".source =
      "${pkgs.traces}/share/bash-completion/completions/traces.bash";
  };
}
