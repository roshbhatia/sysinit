-- Fixed startify configuration
return {
  {
    "mhinz/vim-startify",
    lazy = false,
    priority = 100,
    init = function()
      -- Fix for viminfo file issue - set this BEFORE loading
      vim.g.startify_enable_special = 0
      vim.g.startify_disable_at_vimenter = 0
      vim.g.startify_session_autoload = 0 -- Disable autoload temporarily
    end,
    config = function()
      -- Basic configuratrion
      vim.g.startify_session_dir = vim.fn.stdpath("data") .. "/sessions"
      vim.g.startify_session_persistence = 1
      vim.g.startify_session_delete_buffers = 1
      vim.g.startify_change_to_dir = 1
      vim.g.startify_fortune_use_unicode = 1
      vim.g.startify_files_number = 5
      vim.g.startify_padding_left = 3
      
      -- Simple list structure - avoid custom functions
      vim.g.startify_lists = {
        { type = 'dir',       header = {'   Current Directory:'} },
        { type = 'files',     header = {'   Recent Files:'} },
        { type = 'sessions',  header = {'   Sessions:'} },
        { type = 'bookmarks', header = {'   Bookmarks:'} },
        { type = 'commands',  header = {'   Commands:'} },
      }
      
      -- Simple custom header
      vim.g.startify_custom_header = {
        "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
        "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
        "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
        "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
        "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
        "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
        "",
        "               The extensible text editor                  ",
      }
      
      -- Startify bookmarks
      vim.g.startify_bookmarks = {
        { c = '~/.config/nvim/init.lua' },
        { z = '~/.zshrc' },
      }
      
      -- Simple commands
      vim.g.startify_commands = {
        { f = {'Find File', ':Telescope find_files'} },
        { g = {'Find Word', ':Telescope live_grep'} },
        { r = {'Recent Files', ':Telescope oldfiles'} },
      }
      
      -- Simple helpers to fix Startify issues
      vim.cmd [[
        augroup startify_fixes
          autocmd!
          " Prevent viminfo errors from displaying
          autocmd FileType startify setlocal nomodified
          autocmd User Startified setlocal cursorline
        augroup END
      ]]
    end,
  }
}
