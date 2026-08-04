# The CLIs a single skill owns, as command name -> source path relative to
# skills/.
#
# One list, two consumers, so a third entry needs no second edit:
#   llm/skill-tools.nix        builds each source into a PATH command
#   the skill-render-shape check fails if any of them reaches the installed
#                              skill tree, where it would compete with that
#                              command
#
# Each source sits at the top level of its skill directory on purpose;
# skills/default.nix installs subdirectories only. See D4 in the
# reorganize-llm-module-layout change.
{
  citelock = "citation-verification/citelock.sh";
  wtrun = "wtrun/wtrun.sh";
}
