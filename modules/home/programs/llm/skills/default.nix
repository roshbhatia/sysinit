{
  lib,
  enabledOptInSkills ? [ ],
}:
let
  root = ./.;
  package = import ../lib/skill-package.nix { inherit lib root; };
  inherit (import ./catalog.nix) names optIn;
  compatibility = {
    review-worktree-diff = "Requires managed Neovim and either Rex or WezTerm with agent-diff.";
    review-change-groups = "Requires Changes. Interactive review uses the Sysinit Neovim workbench.";
    inspect-agent-traces = "Requires Traces. Interactive transcript browsing uses the Sysinit Neovim workbench.";
    terminal-wezterm = "Requires WezTerm and the sysinit ty command.";
    workspace-manage = "Requires Git and the seshy sy command.";
    task-manage = "Requires the managed Taskwarrior database. Queued execution also requires tq and Pueue.";
    workflow-run-conductor = "Requires the Microsoft Conductor CLI.";
  };
  enabled = lib.filterAttrs (
    _: name: !(builtins.elem name optIn) || builtins.elem name enabledOptInSkills
  ) names;
in
assert
  builtins.length (lib.unique (builtins.attrValues names))
  == builtins.length (builtins.attrNames names);
lib.mapAttrs' (
  sourceName: name:
  lib.nameValuePair name (
    (package.load sourceName "directory")
    // {
      inherit sourceName;
    }
    // lib.optionalAttrs (compatibility ? ${name}) {
      compatibility = compatibility.${name};
    }
  )
) enabled
