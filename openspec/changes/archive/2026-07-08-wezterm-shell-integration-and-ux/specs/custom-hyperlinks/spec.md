## ADDED Requirements

### Requirement: Nix store paths are clickable hyperlinks
WezTerm SHALL add a hyperlink rule that makes full Nix store paths (`/nix/store/<hash>-<name>`) clickable, opening them in the default file manager or `$EDITOR` via a `file://` URI.

#### Scenario: Click a Nix store path
- **WHEN** the user ctrl-clicks a string matching `/nix/store/[a-z0-9]{32}-[^\s]+`
- **THEN** WezTerm opens the path as a `file://` URI

### Requirement: Full GitHub URLs are hyperlinks
WezTerm SHALL ensure that full `https://github.com/…` URLs are matched by the hyperlink rules (these are covered by `wezterm.default_hyperlink_rules()` but SHALL be explicitly verified as present).

#### Scenario: Click a GitHub URL
- **WHEN** the user ctrl-clicks `https://github.com/owner/repo/issues/123`
- **THEN** WezTerm opens the URL in the default browser

### Requirement: GitHub pull-request and issue shorthand are hyperlinks
WezTerm SHALL add a hyperlink rule that matches `owner/repo#NNN` shorthand and opens `https://github.com/<owner>/<repo>/issues/<NNN>`.

#### Scenario: Click an owner/repo#issue reference
- **WHEN** the user ctrl-clicks `roshbhatia/sysinit#42`
- **THEN** WezTerm opens `https://github.com/roshbhatia/sysinit/issues/42` in the browser
