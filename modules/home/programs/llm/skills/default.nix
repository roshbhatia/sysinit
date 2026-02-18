{
  session-completion = {
    description = "ending sessions: commit, push, hand off context";
    content = import ./session-completion.nix;
  };
  shell-scripting = {
    description = "shell scripts in hack/, Taskfile, shfmt";
    content = import ./shell-scripting.nix;
  };
}
