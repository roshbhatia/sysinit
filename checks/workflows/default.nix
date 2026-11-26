{ pkgs, nuFunctions }:
let
  nuCheck = import ../lib/nushell.nix { inherit pkgs; };
in
{
  task-commands = import ./task-commands.nix { inherit pkgs; };

  mail-actions = import ./mail.nix { inherit pkgs; };

  git-ai-integration = import ./git-ai-integration.nix { inherit pkgs; };

  git-ai-maintenance = import ./git-ai-maintenance.nix { inherit pkgs; };

  tq = import ./tq.nix { inherit pkgs; };

  tq-browser = import ./tq-browser.nix { inherit pkgs; };

  tq-picker = import ./tq-picker.nix { inherit pkgs; };

  review-checkpoint = nuCheck {
    name = "review-checkpoint";
    script = ./review-checkpoint.nu;
    sources = [ ../lib/process.nu ];
    arguments = [ ../../modules/home/programs/git/review-checkpoint.nu ];
    inputs = [ pkgs.git ];
  };

  ty = nuCheck {
    name = "ty-cli";
    script = ../lib/command-contracts.nu;
    sources = [ ../lib/process.nu ];
    arguments = [
      "help"
      "${pkgs.sysinit-utils}/bin/ty"
      "ty catalog"
    ];
  };

  slack-guard = import ./slack-guard.nix { inherit pkgs; };

  pr-workflow = import ./pr-workflow.nix { inherit pkgs nuFunctions; };

  gh-dash-pr = nuCheck {
    name = "gh-dash-pr-test";
    script = ../lib/command-contracts.nu;
    sources = [ ../lib/process.nu ];
    arguments = [ "gh-dash" ];
    inputs = [ pkgs.sysinit-gh-dash ];
  };

  gh-pr-state = nuCheck {
    name = "gh-pr-state-test";
    script = ./gh-pr-state.nu;
    sources = [ ../lib/process.nu ];
    arguments = [ ../../modules/home/programs/gh-pr-state.nu ];
  };

  changes-integration = import ./changes-integration.nix { inherit pkgs; };
}
