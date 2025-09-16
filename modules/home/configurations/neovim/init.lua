require("sysinit.pkg.pre.profiler").setup()

vim.env.PATH = vim.fn.getenv("PATH")
package.path = package.path
  .. ";"
  .. vim.fn.stdpath("config")
  .. "/?.lua"
  .. ";"
  .. vim.fn.stdpath("config")
  .. "/lua/?.lua"

require("sysinit.pkg.opts.leader").setup()
require("sysinit.pkg.opts.environment").setup()
require("sysinit.pkg.opts.editor").setup()
require("sysinit.pkg.opts.search").setup()
require("sysinit.pkg.opts.indentation").setup()
require("sysinit.pkg.opts.wrapping").setup()
require("sysinit.pkg.opts.split_behavior").setup()
require("sysinit.pkg.opts.performance").setup()
require("sysinit.pkg.opts.scroll").setup()
require("sysinit.pkg.opts.ui").setup()
require("sysinit.pkg.opts.folding").setup()
require("sysinit.pkg.opts.completion").setup()
require("sysinit.pkg.opts.autoread").setup()
require("sysinit.pkg.opts.undo").setup()

require("sysinit.pkg.autocmds.buf").setup()
require("sysinit.pkg.autocmds.force_transparency").setup()
require("sysinit.pkg.autocmds.help").setup()
require("sysinit.pkg.autocmds.msg-dump").setup()
require("sysinit.pkg.autocmds.wezterm").setup()

require("sysinit.pkg.utils.plugin_manager").setup_package_manager()
require("sysinit.pkg.utils.plugin_manager").setup_plugins({
  require("sysinit.plugins.core.luarocks"),
  require("sysinit.plugins.core.plenary"),
  require("sysinit.plugins.debugger.nvim-dap-docker"),
  require("sysinit.plugins.debugger.nvim-dap-go"),
  require("sysinit.plugins.debugger.nvim-dap-view"),
  require("sysinit.plugins.debugger.nvim-dap-virtual-text"),
  require("sysinit.plugins.debugger.nvim-dap"),
  require("sysinit.plugins.editor.bqf"),
  require("sysinit.plugins.editor.colorizer"),
  require("sysinit.plugins.editor.comment"),
  require("sysinit.plugins.editor.foldsign"),
  require("sysinit.plugins.editor.hlchunk"),
  require("sysinit.plugins.editor.hop"),
  require("sysinit.plugins.editor.intellitab"),
  require("sysinit.plugins.editor.markdown-preview"),
  require("sysinit.plugins.editor.marks"),
  require("sysinit.plugins.editor.move"),
  require("sysinit.plugins.editor.multicursor"),
  require("sysinit.plugins.editor.render-markdown"),
  require("sysinit.plugins.file.neo-tree"),
  require("sysinit.plugins.file.oil"),
  require("sysinit.plugins.file.persisted"),
  require("sysinit.plugins.file.telescope"),
  require("sysinit.plugins.git.blamer"),
  require("sysinit.plugins.git.diffview"),
  require("sysinit.plugins.git.gitsigns"),
  require("sysinit.plugins.intellicode.blink-cmp"),
  require("sysinit.plugins.intellicode.cmp-copilot"),
  require("sysinit.plugins.intellicode.colorful-menu"),
  require("sysinit.plugins.intellicode.copilot"),
  require("sysinit.plugins.intellicode.conform"),
  require("sysinit.plugins.intellicode.diaglist"),
  require("sysinit.plugins.intellicode.dropbar"),
  require("sysinit.plugins.intellicode.fastaction"),
  require("sysinit.plugins.intellicode.friendly-snippets"),
  require("sysinit.plugins.intellicode.glance"),
  require("sysinit.plugins.intellicode.lazydev"),
  require("sysinit.plugins.intellicode.lsp-lines"),
  require("sysinit.plugins.intellicode.lspkind"),
  require("sysinit.plugins.intellicode.luasnip"),
  require("sysinit.plugins.intellicode.minty"),
  require("sysinit.plugins.intellicode.none-ls"),
  require("sysinit.plugins.intellicode.nvim-autopairs"),
  require("sysinit.plugins.intellicode.nvim-lspconfig"),
  require("sysinit.plugins.intellicode.opencode"),
  require("sysinit.plugins.intellicode.pretty-hover"),
  require("sysinit.plugins.intellicode.refactoring"),
  require("sysinit.plugins.intellicode.schemastore"),
  require("sysinit.plugins.intellicode.sort"),
  require("sysinit.plugins.intellicode.treesitter-context"),
  require("sysinit.plugins.intellicode.treesitter"),
  require("sysinit.plugins.intellicode.typescript-tools"),
  require("sysinit.plugins.keymaps.which-key"),
  require("sysinit.plugins.library.nio"),
  require("sysinit.plugins.library.nui"),
  require("sysinit.plugins.library.snacks"),
  require("sysinit.plugins.library.volt"),
  require("sysinit.plugins.ui.auto-cmdheight"),
  require("sysinit.plugins.ui.devicons"),
  require("sysinit.plugins.ui.dressing"),
  require("sysinit.plugins.ui.edgy"),
  require("sysinit.plugins.ui.live-command"),
  require("sysinit.plugins.ui.no-neck-pain"),
  require("sysinit.plugins.ui.minimap"),
  require("sysinit.plugins.ui.scrollview"),
  require("sysinit.plugins.ui.smart-splits"),
  require("sysinit.plugins.ui.staline"),
  require("sysinit.plugins.ui.themes"),
  require("sysinit.plugins.ui.tiny-glimmer"),
  require("sysinit.plugins.ui.tiny-devicons-auto-colors"),
  require("sysinit.plugins.ui.wilder"),
})

require("sysinit.pkg.keybindings.buffer").setup()
require("sysinit.pkg.keybindings.lists").setup()
require("sysinit.pkg.keybindings.marks").setup()
require("sysinit.pkg.keybindings.super").setup()
require("sysinit.pkg.keybindings.undo").setup()
