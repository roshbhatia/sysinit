# Canonical bash-allowlist source. One place that defines "what bash is
# safe to auto-allow"; each agent harness consumes via `formatFor<Harness>`.
#
# tierA — read-only inspection commands. Zero blast radius. Default for
#         every harness that supports an auto-allowlist.
# tierB — reversible local-write commands (formatters, `git add`, `nix
#         build`). Opt-in per harness depending on its trust policy.
#
# Pattern syntax: `<command>` (exact match) or `<command> *` (prefix
# match with anything after). Each formatter maps these patterns into
# its harness's native shape.
{ lib }:

let
  tierA = [
    # git read-only
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

    # openspec read-only
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

    # cocoindex-code read-only
    "ccc search"
    "ccc search *"
    "ccc status"
    "ccc status *"
    "ccc --version"
    "ccc --help"

    # nix read-only
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

    # filesystem reads (commands with no destructive flags)
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

    # search (read-only)
    "grep"
    "grep *"
    "rg"
    "rg *"

    # process / system reads
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

    # GitHub (read-only)
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

    # text utilities (no -i/-w modes)
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

    # misc inspection
    "env"
    "type *"
    "command -v *"
    "shfmt -d *"
    "nixfmt --check *"
    "nixfmt-rfc-style --check *"

    # diff
    "diff *"
    "cmp *"
  ];

  # Reversible local writes. Each entry mutates the working tree or the
  # nix store but is recoverable (`git restore --staged`, `nix profile
  # rollback`, re-running the formatter, etc.). Opt-in per harness.
  tierB = [
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

  # Claude Code: settings.permissions.allow expects a list of "Bash(<pattern>)"
  # strings (plus other tool-class wrappers we don't emit here).
  formatForClaude = tier: builtins.map (cmd: "Bash(${cmd})") tier;

  # Cursor CLI: permissions.allow expects a list of "Shell(<cmd>)" strings.
  formatForCursor = tier: builtins.map (cmd: "Shell(${cmd})") tier;

  # Crush: permissions.allowed_tools is a flat string list. Patterns are
  # passed through verbatim — crush matches by prefix.
  formatForCrush = tier: tier;

  # Amp: amp.permissions is a list of {tool, matches, action} triples.
  # Bash patterns become {tool="Bash", matches={cmd=<pattern>}, action="allow"}.
  formatForAmp =
    tier:
    builtins.map (cmd: {
      tool = "Bash";
      matches = {
        inherit cmd;
      };
      action = "allow";
    }) tier;

  # Goose: shell.allow expects regex patterns. Convert glob `*` → `.*`.
  formatForGoose = tier: {
    shell = {
      allow = builtins.map (cmd: builtins.replaceStrings [ "*" ] [ ".*" ] cmd) tier;
      deny = [ ];
    };
  };

  # Opencode: permission.bash is an attrset keyed by glob pattern with
  # values "allow". Each tier entry "<cmd>" or "<cmd> *" becomes a key.
  # For "<cmd>" (exact, no args) we emit "<cmd>*" because opencode's
  # glob matching is prefix-based — exact-only enforcement would require
  # an opencode-specific syntax we don't emit here.
  formatForOpencode =
    tier:
    let
      toKey =
        cmd:
        if lib.hasSuffix " *" cmd then
          (lib.substring 0 (lib.stringLength cmd - 2) cmd) + "*"
        else
          cmd + "*";
    in
    lib.listToAttrs (builtins.map (cmd: lib.nameValuePair (toKey cmd) "allow") tier);
in
{
  inherit
    tierA
    tierB
    formatForClaude
    formatForCursor
    formatForCrush
    formatForAmp
    formatForGoose
    formatForOpencode
    ;
}
