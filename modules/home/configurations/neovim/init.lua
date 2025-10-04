require("sysinit.config.pre.profiler").setup()

vim.env.PATH = vim.fn.getenv("PATH")
package.path = package.path
  .. ";"
  .. vim.fn.stdpath("config")
  .. "/?.lua"
  .. ";"
  .. vim.fn.stdpath("config")
  .. "/lua/?.lua"

require("sysinit.config.opts.leader").setup()
require("sysinit.config.opts.environment").setup()
require("sysinit.config.opts.editor").setup()
require("sysinit.config.opts.search").setup()
require("sysinit.config.opts.indentation").setup()
require("sysinit.config.opts.wrapping").setup()
require("sysinit.config.opts.split_behavior").setup()
require("sysinit.config.opts.performance").setup()
require("sysinit.config.opts.scroll").setup()
require("sysinit.config.opts.ui").setup()
require("sysinit.config.opts.folding").setup()
require("sysinit.config.opts.completion").setup()
require("sysinit.config.opts.autoread").setup()
require("sysinit.config.opts.undo").setup()

require("sysinit.config.autocmds.buf").setup()
require("sysinit.config.autocmds.force_transparency").setup()
require("sysinit.config.autocmds.help").setup()
require("sysinit.config.autocmds.msg-dump").setup()
require("sysinit.config.autocmds.wezterm").setup()

require("sysinit.utils.plugin_manager").setup_package_manager()
require("sysinit.utils.plugin_manager").setup_plugins({
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
  require("sysinit.plugins.editor.markview"),
  require("sysinit.plugins.editor.move"),
  require("sysinit.plugins.editor.multicursor"),
  require("sysinit.plugins.file.neo-tree"),
  require("sysinit.plugins.file.oil"),
  require("sysinit.plugins.file.persisted"),
  require("sysinit.plugins.file.telescope"),
  require("sysinit.plugins.git.blamer"),
  require("sysinit.plugins.git.gitsigns"),
  require("sysinit.plugins.git.mini-diff"),
  require("sysinit.plugins.intellicode.ai-terminals"),
  require("sysinit.plugins.intellicode.blink-cmp"),
  require("sysinit.plugins.intellicode.colorful-menu"),
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

require("sysinit.config.keybindings.buffer").setup()
require("sysinit.config.keybindings.lists").setup()
require("sysinit.config.keybindings.marks").setup()
require("sysinit.config.keybindings.super").setup()
require("sysinit.config.keybindings.undo").setup()
