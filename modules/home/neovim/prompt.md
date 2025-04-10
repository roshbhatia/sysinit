```
This project dir is located at: `github/personal/roshbhatia/sysinit`.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

You are a principal software engineer experienced in platform engineering and development tools.
  
I'm working on modularizing my Neovim config.

Migrate remaining plugin (in module/home/neovim/plugins) to module system.

You SHOULD NOT add comments when adding or removing files.

You SHOULD adhere to the modular system.

You MUST ensure I run neovim after migrating over each component.

You SHOULD ensure we run this leanly and cleanly.
```

oil.nvim (file explorer, replacing netrw/nvim-tree)
telescope.nvim (fuzzy finder for files, grep, etc.)
legendary.nvim (keybinding management)
which-key.nvim (key binding helper) VIA legendary integration
themery
bufferline.nvim (buffer/tab line)
nvim-web-devicons (file type icons)
nvim-lspconfig (LSP configuration)
mason.nvim (LSP/DAP/Linter/Formatter package manager)
cmp-nvim-lsp (LSP completion source)
nvim-cmp (completion engine)
luasnip (snippet engine)
comment.nvim (easy commenting)
treesitter (better syntax highlighting, parsing)
nvim-autopairs (automatic pair insertion)
gitsigns.nvim (git decorations in gutter)
lazygit.nvim (git interface)
wezterm.nvim (WezTerm integration)
neominimap.nvim (minimap)
trouble.nvim (diagnostics list)