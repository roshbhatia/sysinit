{ config, browser }:
let
  bin = "${config.home.profileDirectory}/bin";
  editor = name: detail: tool: {
    inherit name detail;
    command = [
      "${bin}/gh-pr-diff"
      "--tool"
      tool
    ];
  };
in
{
  browser = {
    name = "Firefox";
    detail = "Open on github.com";
    bundle = browser;
    kinds = [
      "pull"
      "actions"
    ];
  };
  gh-dash = {
    name = "gh dash";
    detail = "Dashboard, checks, and review actions";
    command = [
      "${bin}/gh"
      "dash"
    ];
  };
  gh-enhance = {
    name = "gh enhance";
    detail = "Watch the run's jobs and logs";
    command = [
      "${bin}/gh"
      "enhance"
    ];
    kinds = [ "actions" ];
  };
  atlas = editor "Neovim (Atlas)" "Review pull requests, threads, and notes" "nvim";
  diffview = editor "Neovim (Diff)" "Read the patch in Diffview" "diffview";
  changes = editor "Changes" "Browse the patch and authorship in Changes" "changes";
  hunk = editor "Hunk" "Review the PR in Hunk" "hunk";
  tuicr = editor "tuicr" "Review the PR in tuicr with line comments" "tuicr";
}
