# neovim configuration

My neovim configuration. It lived in its own `sysinit.nvim` repository for a
while and is back here. One checkout now holds the editor and the harness
config that opens it.

There is no installer. `~/.config/nvim` is a symlink to this directory, created
on activation by `modules/home/programs/neovim/sysinit-nvim.nix`. The target is
`sysinit.neovim.configPath`. Editing a file here changes the next nvim start
with no rebuild. `lazy-lock.json` is tracked, so plugin drift shows up in `git
status`.

The old `curl | bash` install line is gone on purpose. It cloned the standalone
repository over `~/.config/nvim`, which would undo the move and make the next
activation refuse.
