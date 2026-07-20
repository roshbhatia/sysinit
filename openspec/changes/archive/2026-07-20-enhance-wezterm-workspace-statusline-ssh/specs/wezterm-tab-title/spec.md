## ADDED Requirements

### Requirement: Tab titles are never empty and never the bare shell name

The `format-tab-title` handler SHALL always render a meaningful label and SHALL
never emit an empty tab title nor the bare foreground-process name of an
interactive shell (e.g. `zsh`). The label SHALL be chosen by precedence:

1. an explicit, non-numeric tab title set via `tab:set_title()`;
2. otherwise the pane's OSC-2 title, when it is non-empty, non-numeric, and not
   itself a bare shell name;
3. otherwise the basename of the pane's current working directory (with `$HOME`
   collapsed to `~`);
4. otherwise the foreground process name, falling back to `shell`.

A sigil process icon SHALL be prefixed to the label when one is known for the
foreground process; unknown processes render the label alone.

#### Scenario: Shell pane shows its folder, not "zsh"

- **WHEN** a tab's foreground process is an interactive shell sitting in a
  directory
- **THEN** the tab label shows that directory's basename (or `~` for `$HOME`),
  prefixed with the shell's sigil icon, rather than the word `zsh` or an empty
  string

#### Scenario: Folder-based OSC title is supplied by the prompt

- **WHEN** the active prompt (oh-my-posh) is configured with
  `console_title_template = "{{ .Folder }}"`
- **THEN** the shell emits an OSC-2 title carrying the current folder, which the
  handler renders as the tab label even when the working directory is otherwise
  unavailable to WezTerm

#### Scenario: A program's own OSC title is shown verbatim (negative)

- **WHEN** a TUI program (e.g. Claude Code) sets its own OSC-2 title
- **THEN** the handler renders that title as-is, without slugifying,
  abbreviating, or re-branding it

### Requirement: No application-specific tab-title slugging

The handler SHALL NOT special-case any application to rewrite its title. In
particular it SHALL NOT shorten a program's OSC-2 title into a hyphenated slug
or prepend an application-specific badge; programs that set an OSC title own
their label.

#### Scenario: Claude Code titles are not hyphenated

- **WHEN** Claude Code sets an OSC-2 task-summary title
- **THEN** the tab shows that summary unchanged, not a hyphenated slug such as
  `sli-dashboard`
