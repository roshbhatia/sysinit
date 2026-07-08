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

    # ast-grep structural search (read-only)
    "ast-grep run *"
    "ast-grep scan *"
    "ast-grep --help"
    "sg run *"
    "sg scan *"
    "sg --help"

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

    # specutil — OpenSpec change visualization, planning, rendering (read-only)
    "specutil graph"
    "specutil graph *"
    "specutil render *"
    "specutil plan *"
    "specutil diff *"
    "specutil tui"
    "specutil serve"
    "specutil serve *"
    "specutil --help"
    "specutil --version"
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

  # MCP tool patterns for Claude Code's permissions.allow list.  Claude Code
  # accepts bare "mcp__<server>__<tool>" strings (no Bash() wrapper) alongside
  # the Bash()-wrapped entries.  Glob is valid only in the tool position after a
  # LITERAL server prefix — "mcp__<server>__*" is valid; "mcp__*__*" is not.
  # Keep in sync with mcp-servers.nix (for plugin/static servers) and with the
  # claude.ai marketplace integrations list (add a row when a new server is
  # connected via the web UI).
  tierMcp = [
    # structural code search — read-only, zero blast radius
    "mcp__ast-grep__*"
    # AWS service docs — remote read-only
    "mcp__aws-knowledge-mcp-server__*"
    # cross-harness memory store
    "mcp__basic-memory__*"
    # Codex-as-subagent — intentional delegation, user-initiated
    "mcp__codex-mcp__*"
    # Playwright browser automation — user has opted in
    "mcp__playwright__*"

    # home-manager plugin MCP servers (declared in mcp-servers.nix)
    "mcp__plugin_claude-code-home-manager_ast-grep__*"
    "mcp__plugin_claude-code-home-manager_aws-knowledge-mcp-server__*"
    "mcp__plugin_claude-code-home-manager_basic-memory__*"
    "mcp__plugin_claude-code-home-manager_codex-mcp__*"
    "mcp__plugin_claude-code-home-manager_playwright__*"

    # claude.ai marketplace integrations — one entry per connected server.
    # Add a row here when connecting a new server via claude.ai/settings/integrations.
    "mcp__claude_ai_AWS_Marketplace__*"
    "mcp__claude_ai_Airtable__*"
    "mcp__claude_ai_Ashby__*"
    "mcp__claude_ai_Canva__*"
    "mcp__claude_ai_Clay__*"
    "mcp__claude_ai_Dust__*"
    "mcp__claude_ai_Fathom__*"
    "mcp__claude_ai_Figma__*"
    "mcp__claude_ai_Gmail__*"
    "mcp__claude_ai_Google_Ads__*"
    "mcp__claude_ai_Google_Calendar__*"
    "mcp__claude_ai_Google_Drive__*"
    "mcp__claude_ai_Granola__*"
    "mcp__claude_ai_Hex__*"
    "mcp__claude_ai_HubSpot__*"
    "mcp__claude_ai_Intercom__*"
    "mcp__claude_ai_Ironclad_Contracts__*"
    "mcp__claude_ai_LaunchDarkly__*"
    "mcp__claude_ai_Linear__*"
    "mcp__claude_ai_Lusha__*"
    "mcp__claude_ai_Meta_Ads__*"
    "mcp__claude_ai_Microsoft_365__*"
    "mcp__claude_ai_Notion__*"
    "mcp__claude_ai_Outreach__*"
    "mcp__claude_ai_Postman__*"
    "mcp__claude_ai_Risotto__*"
    "mcp__claude_ai_Salesforce_-_ADMIN_Metadata__*"
    "mcp__claude_ai_Salesforce_ADMIN_write_delete__*"
    "mcp__claude_ai_Salesforce_Read_Only__*"
    "mcp__claude_ai_Sentry__*"
    "mcp__claude_ai_Slack__*"
    "mcp__claude_ai_Superhuman_Mail__*"
    "mcp__claude_ai_Vercel__*"
    "mcp__claude_ai_Zapier__*"
    "mcp__claude_ai_Zoom_for_Claude__*"
    "mcp__claude_ai_incident_io__*"
    "mcp__claude_ai_laurel-ask__*"
    "mcp__claude_ai_mkt1__*"
  ];
in
{
  inherit
    tierA
    tierB
    tierMcp
    formatForClaude
    formatForCursor
    formatForAmp
    formatForGoose
    formatForOpencodeWithAction
    formatForOpencode
    ;
}
