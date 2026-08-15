{ lib }:

let
  tierA = [
    "git status"
    "git status *"
    "git diff"
    "git diff *"
    "git log"
    "git log *"
    "git show"
    "git show *"
    "git blame *"
    "git ls-files"
    "git ls-files *"
    "git branch"
    "git branch --show-current"
    "git branch -v"
    "git branch --list *"
    "git remote -v"
    "git remote get-url *"
    "git rev-parse *"
    "git config --get *"
    "git config --list"
    "git config --list *"
    "git check-ignore -v *"
    "git tag"
    "git tag --list *"
    "git describe *"
    "git stash list"

    "openspec list"
    "openspec list *"
    "openspec status"
    "openspec status *"
    "openspec instructions *"
    "openspec validate"
    "openspec validate *"
    "openspec show *"
    "openspec schemas"
    "openspec schema which"
    "openspec schema which *"
    "openspec schema validate"
    "openspec schema validate *"
    "openspec schema show *"
    "openspec config get *"
    "openspec config list"
    "openspec config list *"
    "openspec config path"
    "openspec templates *"
    "openspec --version"
    "openspec --help"

    "ast-grep run *"
    "ast-grep scan *"
    "ast-grep --help"
    "sg run *"
    "sg scan *"
    "sg --help"

    "nix eval *"
    "nix flake check"
    "nix flake check *"
    "nix flake show"
    "nix flake show *"
    "nix flake metadata"
    "nix flake metadata *"
    "nix flake info"
    "nix flake info *"
    "nix flake lock --update-input *"
    "nix path-info *"
    "nix derivation show *"
    "nix log *"
    "nix hash *"
    "nix-prefetch-url *"
    "nix store prefetch-file *"
    "nix store ls *"
    "nix store path-from-hash-part *"

    "ls"
    "ls *"
    "pwd"
    "cat *"
    "head"
    "head *"
    "tail"
    "tail *"
    "wc"
    "wc *"
    "which *"
    "file *"
    "stat *"
    "du *"
    "tree"
    "tree *"
    "realpath *"
    "readlink *"
    "basename *"
    "dirname *"

    "grep"
    "grep *"
    "rg"
    "rg *"

    "ps"
    "ps *"
    "lsof *"
    "whoami"
    "id"
    "hostname"
    "hostname -s"
    "uname"
    "uname *"
    "top -l 1"
    "top -l 1 *"
    "uptime"
    "date"
    "date *"
    "system_profiler *"
    "defaults read *"
    "sw_vers"
    "sysctl -n *"

    "gh pr list"
    "gh pr list *"
    "gh pr view"
    "gh pr view *"
    "gh pr diff *"
    "gh issue list"
    "gh issue list *"
    "gh issue view *"
    "gh repo view"
    "gh repo view *"
    "gh search code *"
    "gh search repos *"
    "gh search issues *"
    "gh search prs *"
    "gh search commits *"
    "gh release list"
    "gh release list *"
    "gh release view *"
    "gh workflow list"
    "gh workflow view *"
    "gh run list"
    "gh run list *"
    "gh run view *"
    "gh auth status"
    "gh api GET *"
    "gh api -X GET *"

    "gh stack view"
    "gh stack view *"
    "gh stack up"
    "gh stack up *"
    "gh stack down"
    "gh stack down *"
    "gh stack top"
    "gh stack bottom"
    "gh stack trunk"
    "gh stack --help"
    "gh stack checkout *"

    "echo *"
    "printf *"
    "sort"
    "sort *"
    "uniq"
    "uniq *"
    "cut *"
    "tr *"
    "rev"
    "rev *"
    "column *"
    "jq *"
    "yq *"

    "env"
    "type *"
    "command -v *"
    "shfmt -d *"
    "nixfmt --check *"
    "nixfmt-rfc-style --check *"

    "diff *"
    "cmp *"

    "specutil graph"
    "specutil graph *"
    "specutil render *"
    "specutil check"
    "specutil check *"
    "specutil next"
    "specutil next *"
    "specutil review show *"
    "specutil review diff *"
    "specutil web"
    "specutil web *"
    "specutil --help"
    "specutil --version"

    "utils note list *"
    "utils note list"
    "utils note path"
  ];

  tierB = [
    "utils note add *"
    "utils note answer *"

    "git add"
    "git add *"
    "git restore --staged *"
    "nix build"
    "nix build *"
    "nh os build"
    "nh os build *"
    "nix fmt"
    "nix fmt *"
    "nixfmt *"
    "nixfmt-rfc-style *"
    "shfmt -w *"
    "shfmt -i 2 -ci -sr -s -w *"
    "mkdir -p *"
  ];

  destructiveDenyRules = [
    {
      regex = "git[[:space:]]+push\\b[^;&|]*([[:space:]]-f([[:space:]]|$)|--force)";
      reason = "Force-pushing is prohibited (global CLAUDE.md: no force-push).";
    }
    {
      regex = "(--no-verify|--no-gpg-sign)\\b";
      reason = "Hook-bypass flags are prohibited (global CLAUDE.md: no --no-verify / --no-gpg-sign).";
    }
    {
      regex = "git[[:space:]]+reset\\b[^;&|]*--hard\\b";
      reason = "git reset --hard is prohibited without explicit instruction (global CLAUDE.md).";
    }
    {
      regex = "git[[:space:]]+clean\\b[^;&|]*-[a-zA-Z]*f";
      reason = "git clean -f is prohibited without explicit instruction (global CLAUDE.md).";
    }
    {
      regex = "git[[:space:]]+branch\\b[^;&|]*-D\\b";
      reason = "git branch -D (force-delete) is prohibited without explicit instruction (global CLAUDE.md).";
    }
    {
      regex = "git[[:space:]]+branch\\b[^;&|]*--delete[^;&|]*--force\\b";
      reason = "git branch --delete --force is prohibited without explicit instruction (global CLAUDE.md).";
    }
  ];

  destructiveDenyRegexes = builtins.map (r: r.regex) destructiveDenyRules;

  destructiveDenyGlobs = [
    "git push --force*"
    "git push * --force*"
    "git push -f*"
    "git push * -f*"
    "git reset --hard*"
    "git reset * --hard*"
    "git clean -f*"
    "git clean -d*"
    "git clean * -f*"
    "git branch -D*"
    "git branch * -D*"
    "git * --no-verify*"
    "git * --no-gpg-sign*"
  ];

  globPrefix = pattern: lib.head (lib.splitString "*" pattern);
  overlaps =
    allowPattern: denyGlob:
    let
      a = globPrefix allowPattern;
      d = globPrefix denyGlob;
    in
    lib.hasPrefix a d || lib.hasPrefix d a;

  formatForPi =
    {
      allowTiers,
      denyGlobs,
      mcpTier,
      yolo,
    }:
    let
      emittedAllows = if yolo then [ ] else allowTiers;
      emittedMcp = if yolo then [ ] else mcpTier;
      emittedDenies = lib.filter (d: !(lib.any (a: overlaps a d) emittedAllows)) denyGlobs;
      allowEntry = pattern: lib.nameValuePair pattern "allow";
      denyEntry = pattern: lib.nameValuePair pattern "deny";
    in
    {
      "*" = "ask";
      read = "allow";
      skill = "allow";
      bash = {
        "*" = "ask";
      }
      // builtins.listToAttrs (map allowEntry emittedAllows)
      // builtins.listToAttrs (map denyEntry emittedDenies);
      mcp = {
        "*" = "ask";
      }
      // builtins.listToAttrs (map allowEntry emittedMcp);
    };

  formatForClaude = tier: builtins.map (cmd: "Bash(${cmd})") tier;

  formatForCursor = tier: builtins.map (cmd: "Shell(${cmd})") tier;

  formatForAmp =
    tier:
    builtins.map (cmd: {
      tool = "Bash";
      matches = {
        inherit cmd;
      };
      action = "allow";
    }) tier;

  formatForOpencodeWithAction =
    action: tier:
    let
      toKey =
        cmd:
        if lib.hasSuffix " *" cmd then
          (lib.substring 0 (lib.stringLength cmd - 2) cmd) + "*"
        else
          cmd + "*";
    in
    lib.listToAttrs (builtins.map (cmd: lib.nameValuePair (toKey cmd) action) tier);

  formatForOpencode = formatForOpencodeWithAction "allow";

  formatDestructiveForCursor = patterns: builtins.map (cmd: "Shell(${cmd})") patterns;

  stripTrailingGlob =
    cmd: if lib.hasSuffix " *" cmd then lib.substring 0 (lib.stringLength cmd - 2) cmd else cmd;

  formatForDevin = tier: builtins.map (cmd: "Exec(${stripTrailingGlob cmd})") tier;
  formatDestructiveForDevin = patterns: builtins.map (cmd: "Exec(${stripTrailingGlob cmd})") patterns;

  formatDestructiveForOpencode =
    patterns: lib.listToAttrs (builtins.map (cmd: lib.nameValuePair cmd "deny") patterns);
  formatDestructiveForAmp =
    patterns:
    builtins.map (cmd: {
      tool = "Bash";
      matches = {
        inherit cmd;
      };
      action = "reject";
    }) patterns;

  slackSendTools = [
    "mcp__claude_ai_Slack__slack_send_message"
    "mcp__claude_ai_Slack__slack_send_message_draft"
    "mcp__claude_ai_Slack__slack_schedule_message"
  ];

  tierMcp = [
    "mcp__ast-grep__*"
    "mcp__basic-memory__*"
    "mcp__playwright__*"

    "mcp__plugin_claude-code-home-manager_ast-grep__*"
    "mcp__plugin_claude-code-home-manager_basic-memory__*"
    "mcp__plugin_claude-code-home-manager_playwright__*"

    "mcp__plugin_claude-code-home-manager_agentgateway__*"
  ];
in
{
  inherit
    tierA
    tierB
    tierMcp
    slackSendTools
    destructiveDenyRules
    destructiveDenyRegexes
    destructiveDenyGlobs
    formatForClaude
    formatForPi
    formatForCursor
    formatForAmp
    formatForOpencodeWithAction
    formatForOpencode
    formatForDevin
    formatDestructiveForOpencode
    formatDestructiveForAmp
    formatDestructiveForCursor
    formatDestructiveForDevin
    ;
}
