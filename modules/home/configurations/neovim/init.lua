require("sysinit.config.pre.profiler").setup()

vim.env.PATH = vim.fn.getenv("PATH")
---@diagnostic disable-next-line: inject-field
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
require("sysinit.config.autocmds.msg-dump").setup()
require("sysinit.config.autocmds.nvim-rpc").setup()

require("sysinit.utils.plugin_manager").setup_package_manager()
require("sysinit.utils.plugin_manager").setup_plugins({
  require("sysinit.plugins.core.luarocks"),
  require("sysinit.plugins.core.plenary"),
  require("sysinit.plugins.debugger.nvim-dap"),
  require("sysinit.plugins.debugger.nvim-dap-docker"),
  require("sysinit.plugins.debugger.nvim-dap-go"),
  require("sysinit.plugins.debugger.nvim-dap-view"),
  require("sysinit.plugins.debugger.nvim-dap-virtual-text"),
  require("sysinit.plugins.editor.bqf"),
  require("sysinit.plugins.editor.colorizer"),
  require("sysinit.plugins.editor.comment"),
  require("sysinit.plugins.editor.guess-indent"),
  require("sysinit.plugins.editor.hlchunk"),
  require("sysinit.plugins.editor.hop"),
  require("sysinit.plugins.editor.markdown-preview"),
  require("sysinit.plugins.editor.marks"),
  require("sysinit.plugins.editor.move"),
  require("sysinit.plugins.editor.surround"),
  require("sysinit.plugins.file.neo-tree"),
  require("sysinit.plugins.file.grug-far"),
  require("sysinit.plugins.file.oil"),
  require("sysinit.plugins.file.persisted"),
  require("sysinit.plugins.file.telescope"),
  require("sysinit.plugins.git.blamer"),
  require("sysinit.plugins.git.codediff"),
  require("sysinit.plugins.git.gitsigns"),
  require("sysinit.plugins.git.octo"),
  require("sysinit.plugins.git.neogit"),
  require("sysinit.plugins.intellicode.navigation.outline"),
  require("sysinit.plugins.intellicode.completion.blink"),
  require("sysinit.plugins.intellicode.completion.menu"),
  require("sysinit.plugins.intellicode.formatting.conform"),
  require("sysinit.plugins.intellicode.ui.diaglist"),
  require("sysinit.plugins.intellicode.navigation.dropbar"),
  require("sysinit.plugins.intellicode.completion.friendly-snippets"),
  require("sysinit.plugins.intellicode.navigation.glance"),
  require("sysinit.plugins.intellicode.lazydev"),
  require("sysinit.plugins.intellicode.ui.lines"),
  require("sysinit.plugins.intellicode.completion.kind"),
  require("sysinit.plugins.intellicode.completion.snippets"),
  require("sysinit.plugins.intellicode.ui.minty"),
  require("sysinit.plugins.intellicode.formatting.none-ls"),
  require("sysinit.plugins.intellicode.editing.autopairs"),
  require("sysinit.plugins.intellicode.lsp.config"),
  require("sysinit.plugins.intellicode.ui.hover"),
  require("sysinit.plugins.intellicode.editing.refactoring"),
  require("sysinit.plugins.intellicode.schemastore"),
  require("sysinit.plugins.intellicode.formatting.sort"),
  require("sysinit.plugins.intellicode.navigation.context"),
  require("sysinit.plugins.intellicode.editing.treesitter"),
  require("sysinit.plugins.intellicode.typescript-tools"),
  require("sysinit.plugins.keymaps.which-key"),
  require("sysinit.plugins.library.nio"),
  require("sysinit.plugins.library.nui"),
  require("sysinit.plugins.library.snacks"),
  require("sysinit.plugins.orgmode.nvim-orgmode"),
  require("sysinit.plugins.ui.alpha"),
  require("sysinit.plugins.ui.devicons"),
  require("sysinit.plugins.ui.live-command"),
  require("sysinit.plugins.ui.scrollview"),
  require("sysinit.plugins.ui.smart-splits"),
  require("sysinit.plugins.ui.staline"),
  require("sysinit.plugins.ui.themes"),
  require("sysinit.plugins.ui.tiny-glimmer"),
  require("sysinit.plugins.ui.tiny-devicons-auto-colors"),
  require("sysinit.plugins.ui.wilder"),
})

require("sysinit.config.keybindings.lists").setup()
require("sysinit.config.keybindings.marks").setup()
require("sysinit.config.keybindings.super").setup()
require("sysinit.config.keybindings.undo").setup()
require("sysinit.config.keybindings.visual").setup()
