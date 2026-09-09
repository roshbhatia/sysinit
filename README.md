# sysinit

```ascii
          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖
          ▜███▙       ▜███▙  ▟███▛
           ▜███▙       ▜███▙▟███▛
            ▜███▙       ▜██████▛
     ▟█████████████████▙ ▜████▛     ▟▙
    ▟███████████████████▙ ▜███▙    ▟██▙
           ▄▄▄▄▖           ▜███▙  ▟███▛
          ▟███▛             ▜██▛ ▟███▛
         ▟███▛               ▜▛ ▟███▛
▟███████████▛                  ▟██████████▙
▜██████████▛                  ▟███████████▛
      ▟███▛ ▟▙               ▟███▛
     ▟███▛ ▟██▙             ▟███▛
    ▟███▛  ▜███▙           ▝▀▀▀▀
    ▜██▛    ▜███▙ ▜██████████████████▛
     ▜▛     ▟████▙ ▜████████████████▛
           ▟██████▙       ▜███▙
          ▟███▛▜███▙       ▜███▙
         ▟███▛  ▜███▙       ▜███▙
         ▝▀▀▀    ▀▀▀▀▘       ▀▀▀▘
```

This comprises most of my dotfiles, managed (mostly) by `nix`.

## Quick Start

### Build and Apply Configuration

```bash
# The first run needs `nix run`.
nix run nixpkgs#nh -- darwin switch .
nh darwin switch .
```
### Profiles

Every host picks one profile in `hosts/default.nix`. The three are additive, so
a package is listed once at the lowest profile that needs it.

| Profile | For | Holds |
| --- | --- | --- |
| `minimal` | a box you reach over ssh | a shell, a pager, an editor, git |
| `dev` | a box you build on | the above plus toolchains and the agent runtime |
| `workstation` | a box you sit in front of | the above plus the GUI |

### Installing the Editor on a Box With No Nix

`bootstrap/bootstrap.sh` clones [sysinit.nvim](https://github.com/roshbhatia/sysinit.nvim)
into `~/.local/share/sysinit.nvim` and links it to `~/.config/nvim`.
Neovim, Git, and a C compiler must already be on PATH. Existing configurations
are preserved; the script stops if another configuration occupies that path.

```bash
curl -fsSL https://raw.githubusercontent.com/roshbhatia/sysinit/main/bootstrap/bootstrap.sh | bash
```

It is re-runnable and honors `SYSINIT_REMOTE`, `SYSINIT_BRANCH`, and
`SYSINIT_CHECKOUT`.

### Editor and terminal configuration

[sysinit.nvim](https://github.com/roshbhatia/sysinit.nvim) and
[sysinit.wezterm](https://github.com/roshbhatia/sysinit.wezterm) own their Lua,
Home Manager modules, and behavior tests. This flake selects their versions
and supplies machine settings. Set `sysinit.neovim.configPath` to a writable
checkout for editor development; its default uses the pinned source.

The WezTerm picker keeps its live session tree. Within the picker, `!` lists
Tether hosts, `@` lists Seshy sessions, and `#` lists zoxide directories.
Each provider owns its icon, rows, and open action. Install providers
individually, or use Seshy's and Tether's `full` Nix packages and `-all`
Homebrew formulae.

[agent-notes](https://github.com/roshbhatia/agent-notes) owns the notes CLI and
Neovim plugin. Its README includes vim.pack, Lazy, and Nixvim installation.
Scheduled source updates advance fixed revisions and stable tags, update
nested locks, and run checks before proposing changes.

### Creating a Discrete Host Repository

To create a separate repository that consumes this flake for host-specific configurations (i.e., work machine):

```bash
nix flake init -t github:roshbhatia/sysinit#discrete
```
