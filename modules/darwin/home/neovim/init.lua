vim.env.PATH = vim.fn.getenv("PATH")
package.path = package.path
	.. ";"
	.. vim.fn.stdpath("config")
	.. "/?.lua"
	.. ";"
	.. vim.fn.stdpath("config")
	.. "/lua/?.lua"

local core = require("sysinit.pkg.core")
core.register_leader()
core.register_options()
core.register_keybindings()
core.register_autocmds()

require("sysinit.pkg.plugin_manager").setup_package_manager()
require("sysinit.pkg.plugin_manager").setup_plugins({
	require("sysinit.plugins.collections.snacks"),
	require("sysinit.plugins.debugger.dap"),
	require("sysinit.plugins.debugger.dap-ui"),
	require("sysinit.plugins.debugger.dap-virtual-text"),
	require("sysinit.plugins.debugger.mason-nvim-dap"),
	require("sysinit.plugins.editor.comment"),
	require("sysinit.plugins.editor.formatter"),
	require("sysinit.plugins.editor.hlchunk"),
	require("sysinit.plugins.editor.hop"),
	require("sysinit.plugins.editor.intellitab"),
	require("sysinit.plugins.editor.far"),
	require("sysinit.plugins.editor.foldsign"),
	require("sysinit.plugins.editor.render-markdown"),
	require("sysinit.plugins.editor.surround"),
	require("sysinit.plugins.file.diffview"),
	require("sysinit.plugins.file.editor"),
	require("sysinit.plugins.file.session"),
	require("sysinit.plugins.file.telescope"),
	require("sysinit.plugins.file.tree"),
	require("sysinit.plugins.git.blamer"),
	require("sysinit.plugins.git.client"),
	require("sysinit.plugins.git.fugitive"),
	require("sysinit.plugins.git.signs"),
	require("sysinit.plugins.intellicode.aider"),
	require("sysinit.plugins.intellicode.avante"),
	require("sysinit.plugins.intellicode.cmp-buffer"),
	require("sysinit.plugins.intellicode.cmp-cmdline"),
	require("sysinit.plugins.intellicode.cmp-git"),
	require("sysinit.plugins.intellicode.cmp-nvim-lsp"),
	require("sysinit.plugins.intellicode.cmp-nvim-lua"),
	require("sysinit.plugins.intellicode.cmp-path"),
	require("sysinit.plugins.intellicode.codecompanion"),
	require("sysinit.plugins.intellicode.copilot-chat"),
	require("sysinit.plugins.intellicode.copilot-cmp"),
	require("sysinit.plugins.intellicode.copilot"),
	require("sysinit.plugins.intellicode.dropbar"),
	require("sysinit.plugins.intellicode.friendly-snippets"),
	require("sysinit.plugins.intellicode.guess-indent"),
	require("sysinit.plugins.intellicode.linters"),
	require("sysinit.plugins.intellicode.luasnip"),
	require("sysinit.plugins.intellicode.lspsaga"),
	require("sysinit.plugins.intellicode.mason-lspconfig"),
	require("sysinit.plugins.intellicode.mason-tool-installer"),
	require("sysinit.plugins.intellicode.mason"),
	require("sysinit.plugins.intellicode.mcphub"),
	require("sysinit.plugins.intellicode.nvim-autopairs"),
	require("sysinit.plugins.intellicode.nvim-cmp"),
	require("sysinit.plugins.intellicode.nvim-lspconfig"),
	require("sysinit.plugins.intellicode.outline"),
	require("sysinit.plugins.intellicode.schemastore"),
	require("sysinit.plugins.intellicode.sort"),
	require("sysinit.plugins.intellicode.trailspace"),
	require("sysinit.plugins.intellicode.treesitter-textobjects"),
	require("sysinit.plugins.intellicode.treesitter"),
	require("sysinit.plugins.intellicode.trouble"),
	require("sysinit.plugins.keymaps.which-key"),
	require("sysinit.plugins.kubernetes.yaml"),
	require("sysinit.plugins.library.image"),
	require("sysinit.plugins.library.nio"),
	require("sysinit.plugins.library.nui"),
	require("sysinit.plugins.ui.alpha"),
	require("sysinit.plugins.ui.devicons"),
	require("sysinit.plugins.ui.dressing"),
	require("sysinit.plugins.ui.edgy"),
	require("sysinit.plugins.ui.live-command"),
	require("sysinit.plugins.ui.minimap"),
	require("sysinit.plugins.ui.smart-splits"),
	require("sysinit.plugins.ui.statusbar"),
	require("sysinit.plugins.ui.terminal"),
	require("sysinit.plugins.ui.themery"),
	require("sysinit.plugins.ui.wilder"),
})
