require("sysinit.config.pre.profiler").setup()

require("sysinit.config.opts.autoread").setup()
require("sysinit.config.opts.completion").setup()
require("sysinit.config.opts.editor").setup()
require("sysinit.config.opts.filetypes").setup()
require("sysinit.config.opts.folding").setup()
require("sysinit.config.opts.indentation").setup()
require("sysinit.config.opts.leader").setup()
require("sysinit.config.opts.performance").setup()
require("sysinit.config.opts.search").setup()
require("sysinit.config.opts.ui").setup()
require("sysinit.config.opts.undo").setup()
require("sysinit.config.opts.wrapping").setup()

require("sysinit.config.autocmds.buf").setup()
require("sysinit.config.autocmds.msg-dump").setup()
require("sysinit.config.autocmds.nvim-rpc").setup()

require("sysinit.config.usercmds.patch").setup()
require("sysinit.config.usercmds.sudo").setup()

require("sysinit.utils.plugin_manager").setup_package_manager()
require("sysinit.utils.plugin_manager").setup_plugins()

require("sysinit.config.keybindings.lists").setup()
require("sysinit.config.keybindings.super").setup()
require("sysinit.config.keybindings.undo").setup()
require("sysinit.config.keybindings.visual").setup()
