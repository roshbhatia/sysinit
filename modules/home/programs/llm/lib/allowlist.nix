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

    # gh stack (github/gh-stack) — reading and local navigation only.
    # `submit`, `merge`, `push`, `sync`, `unstack`, and `delete` reach GitHub, so
    # they are deliberately absent from every tier and stay owner-gated, exactly
    # like `gh pr create`.
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
    "specutil check"
    "specutil check *"
    "specutil web"
    "specutil web *"
    "specutil --help"
    "specutil --version"

    # specutil lock — writes the identity→externalId mapping after Linear/Notion syncs
    "specutil lock *"

    # diffnote — reading forms only. The writing forms are tierB: this tier is
    # defined above as read-only with zero blast radius, and `add` and `apply`
    # write a file.
    "diffnote list *"
    "diffnote list"
    "diffnote path"
  ];

  # Reversible local writes. Each entry mutates the working tree or the
  # nix store but is recoverable (`git restore --staged`, `nix profile
  # rollback`, re-running the formatter, etc.). Opt-in per harness.
  tierB = [
    # diffnote — review notes on the working-tree diff, rendered by neovim's
    # CodeDiff view. Writes only to its own per-repository store under
    # $XDG_STATE_HOME/agents/diff-notes/, never to the working tree, and a note is
    # removable with `diffnote clear`.
    #
    # `diffnote clear` is deliberately absent from both tiers: it discards review
    # notes the owner may not have read yet, so it asks.
    #
    # Note that pi does NOT read this file. Its gate is
    # @gotgenes/pi-permission-system, configured under ~/.pi/agent/extensions/.
    # These entries serve claude, amp, devin, cursor, and opencode.
    "diffnote add *"
    "diffnote apply *"

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

  # Destructive / irreversible / hook-bypassing command patterns that MUST be
  # denied in every harness (the mechanical floor under the global CLAUDE.md
  # prohibitions). Two representations of the same intent:
  #   destructiveDenyRegexes — ERE, for regex-matching harnesses and as the
  #     canonical reference for the guard scripts. These mirror the patterns
  #     already inlined in claude-bash-guard.sh so all harnesses block the same
  #     forms.
  #   destructiveDenyGlobs — prefix globs, for permission systems that match
  #     command prefixes (opencode permission.bash keys, Amp matches.cmd).
  #     Prefix matching is leakier than regex (a flag after positional args can
  #     slip past), so these harnesses are defense-in-depth behind the robust
  #     script/regex guards; several orderings are listed to widen coverage.
  # Each rule pairs the pattern with the refusal the agent sees. The guard
  # scripts generate their pattern table from this list, so a pattern cannot
  # exist in a script and not here, or differ in form between the two. Before
  # this was shared, five of the six had already drifted.
  #
  # `-f` is anchored on leading whitespace so it cannot match the tail of a
  # branch name. Without the anchor, `git push origin feature-f` is denied.
  # `--force` needs no anchor and also covers `--force-with-lease`.
  #
  # The gap between subcommand and flag is `[^;&|]*`, never `.*`: with `.*` a flag
  # belonging to a LATER command in the same compound satisfies an earlier
  # subcommand's rule. Observed: `git push` alongside `rm -f` was denied as a
  # force-push. A guard that fires on a command the owner did not write trains them
  # to route around it.
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

  # pi, via @gotgenes/pi-permission-system. Its config takes a flat
  # `permission` map: each key is a surface (`bash`, `read`, `mcp`, `skill`, `*`) and
  # each value is either an action or a pattern → action map.
  #
  # ORDER IS NOT AVAILABLE HERE. That extension resolves a pattern map by "last
  # matching pattern wins", and `builtins.toJSON` emits attribute names in
  # alphabetical order, so a deny cannot be placed after an allow on purpose. The
  # policy is therefore built so ordering can never decide an outcome:
  #
  #   * the surface default is `ask`, so anything unlisted prompts rather than runs
  #   * only the tier patterns are `allow`ed, and they are all read-only or reversible
  #   * the destructive globs are `deny`ed, and `assertDenyDisjoint` below proves no
  #     deny glob can be matched by an allow pattern, so the two sets never overlap
  #     and whichever the extension happens to visit last is the same answer
  #
  # `deny` is still worth emitting even though the `ask` default already refuses to
  # auto-run these: a deny needs no human decision, so it cannot be approved by
  # reflex at a prompt.
  # Would this allow pattern match a command that this deny glob also matches? Both
  # are prefix globs, so an overlap exists exactly when one's literal prefix is a
  # prefix of the other's. If any pair overlapped, the outcome would depend on which
  # key `builtins.toJSON` happened to emit last, which is not something to leave to
  # alphabetical order.
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
    }:
    let
      # Only the denies no allow pattern can also match. A deny that overlaps an
      # allow is DROPPED rather than emitted, because pi resolves such a pair by
      # whichever key came last, and that is alphabetical order here.
      #
      # Dropping is safe rather than a hole, for a checkable reason: every dropped
      # deny carries a mid-pattern wildcard, so the only allows it overlaps are the
      # read-only git reads. The dangerous forms those denies exist for name
      # subcommands that appear in NO tier, so they fall to the `ask` default and
      # still never auto-run. What is lost is a silent refusal, replaced by a prompt.
      emittedDenies = lib.filter (d: !(lib.any (a: overlaps a d) allowTiers)) denyGlobs;
      allowEntry = pattern: lib.nameValuePair pattern "allow";
      denyEntry = pattern: lib.nameValuePair pattern "deny";
    in
    {
      "*" = "ask";
      # Reads cannot mutate anything, and pi asks per PATH otherwise, which is a
      # prompt on nearly every turn.
      read = "allow";
      # Skills come from this repository's own tree, so the gate adds nothing.
      skill = "allow";
      bash = {
        "*" = "ask";
      }
      // builtins.listToAttrs (map allowEntry allowTiers)
      // builtins.listToAttrs (map denyEntry emittedDenies);
      mcp = {
        "*" = "ask";
      }
      // builtins.listToAttrs (map allowEntry mcpTier);
    };

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

  # Destructive-deny formatters. Each takes a pattern list and maps it into the
  # harness's native deny shape. Goose has no entry: its config has no
  # command-pattern deny surface, only tool-level permission.yaml gates.
  #   opencode — permission.bash map keyed by glob → "deny".
  #   Amp    — amp.permissions triples with action "reject" (verify the reject
  #            action name against Amp's schema at apply; current allow/ask are
  #            confirmed, reject is the documented block action).
  #   Cursor — permissions.deny takes the same "Shell(<pattern>)" shape as
  #            allow. Without this the cursor config denies nothing at all.
  #   Devin  — permissions.deny takes "Exec(<prefix>)" for shell and
  #            "Read(<glob>)" for files. Devin matches Exec by command prefix,
  #            not by glob, so a trailing " *" is stripped rather than kept.
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

  # Slack MCP tools that send messages — require explicit approval in every
  # harness that supports a per-tool ask/confirm mechanism.  Shared here so
  # all harness configs reference the same list instead of duplicating strings.
  slackSendTools = [
    "mcp__claude_ai_Slack__slack_send_message"
    "mcp__claude_ai_Slack__slack_send_message_draft"
    "mcp__claude_ai_Slack__slack_schedule_message"
  ];

  # MCP tool patterns for Claude Code's permissions.allow list.  Claude Code
  # accepts bare "mcp__<server>__<tool>" strings (no Bash() wrapper) alongside
  # the Bash()-wrapped entries.  Glob is valid only in the tool position after a
  # LITERAL server prefix — "mcp__<server>__*" is valid; "mcp__*__*" is not.
  # Keep in sync with mcp-servers.nix (for plugin/static servers).
  tierMcp = [
    # structural code search — read-only, zero blast radius
    "mcp__ast-grep__*"
    # cross-harness memory store
    "mcp__basic-memory__*"
    # Playwright browser automation — user has opted in
    "mcp__playwright__*"

    # home-manager plugin MCP servers (declared in mcp-servers.nix). Present for
    # hosts that register them directly; a host that routes them through a gateway
    # suppresses these servers and the entries simply match nothing.
    "mcp__plugin_claude-code-home-manager_ast-grep__*"
    "mcp__plugin_claude-code-home-manager_basic-memory__*"
    "mcp__plugin_claude-code-home-manager_playwright__*"

    # The aggregating gateway (sysinit.laurel). One entry, so it grants every tool
    # the gateway fronts, which is strictly coarser than the per-server entries
    # above: the same prefix covers ast-grep, playwright, and every remote target.
    # The owner accepted that trade to get a single MCP entry. The consequence to
    # remember is that ADDING a gateway target silently inherits auto-approval, so
    # the gateway's target list is now a permission surface, not just plumbing.
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
