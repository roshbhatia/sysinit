# CLIs owned by a single skill, built from that skill's own directory.
#
# A script belongs to a skill when the skill is its only consumer and the skill's
# prose is its documentation. `citelock` and `wtrun` meet that test. The
# agent-agnostic scripts under runtime/ do not: harness hooks, the wezterm
# statusline, and the seshy integration all call them, so no skill owns them.
#
# Each source sits at the top level of its skill directory, not under
# `scripts/`. skills/default.nix installs a skill's subdirectories and ignores
# its top-level files, so this placement colocates the source without shipping a
# second copy into ~/.claude/skills, where it would compete with the PATH command
# built here.
{ pkgs, ... }:
let
  # Command name -> source path. Shared with the skill-render-shape check, so a
  # tool added here cannot escape the guard that keeps it out of the skill tree.
  sources = import ./skills/tool-sources.nix;
  sourceOf = name: ./skills + "/${sources.${name}}";

  # Runs one command in a single reusable WezTerm pane (see wtrun.sh). A long or
  # noisy command belongs in its own pane rather than in the conversation pane,
  # and creating a pane per command leaves a trail of them.
  wtrun = pkgs.writeShellApplication {
    name = "wtrun";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.jq
      pkgs.wezterm
    ];
    text = builtins.readFile (sourceOf "wtrun");
  };

  # Used in any repo or seshy session, not a sysinit maintenance script, so it is
  # not in hack/. Single source: the flake check and the pre-commit hook consume
  # the same script. Runtime deps (jq, curl, lychee, monolith, coreutils) are
  # already on PATH via home.packages.
  citelock = pkgs.writeShellScriptBin "citelock" (builtins.readFile (sourceOf "citelock"));
in
{
  home.packages = [
    citelock
    wtrun
  ];
}
