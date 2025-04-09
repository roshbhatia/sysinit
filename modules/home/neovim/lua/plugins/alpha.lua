return {
  "goolord/alpha-nvim",
  dependencies = { 
    "nvim-tree/nvim-web-devicons",
    "nvim-lua/plenary.nvim"
  },
  config = function()
    local alpha = require("alpha")
    local startify = require("alpha.themes.startify")
    
    -- Set devicons as the provider
    startify.section.header.val = {
      "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
      "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
      "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
      "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
      "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
      "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
      "",
      "               The extensible text editor                  ",
    }
    
    startify.file_icons.provider = "require('nvim-web-devicons').get_icon"
    
    -- Customize the top menu items
    local top_buttons = {
      startify.button("f", "  Find file", ":Telescope find_files <CR>"),
      startify.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
      startify.button("r", "  Recently used files", ":Telescope oldfiles <CR>"),
      startify.button("t", "  Find text", ":Telescope live_grep <CR>"),
      startify.button("c", "  Configuration", ":e ~/.config/nvim/init.lua <CR>"),
      startify.button("l", "  Lazy", ":Lazy<CR>"),
      startify.button("q", "  Quit Neovim", ":qa<CR>"),
    }
    
    -- If we have Copilot installed, add a button for it
    if vim.fn.exists("g:loaded_copilot") == 1 then
      table.insert(top_buttons, 4, startify.button("p", "  Copilot", ":Copilot<CR>"))
    end
    
    startify.section.top_buttons.val = top_buttons
    
    -- Configure footer
    local function footer()
      local stats = require("lazy").stats()
      local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
      return { "Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms" }
    end
    
    startify.section.footer.val = footer()
    
    -- Configure options
    startify.opts.layout[1].val = 8 -- Increase padding at top
    
    -- Setup alpha configuration properly
    alpha.setup(startify.config)
    
    -- Add autocommand to prevent folding in the dashboard
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "alpha",
      callback = function()
        vim.opt_local.foldenable = false
      end
    })
    
    -- Enable automatic session loading/saving if available
    if pcall(require, "persistence") then
      -- Add session management buttons
      table.insert(startify.section.top_buttons.val, 3, startify.button("s", "  Restore Session", [[:lua require("persistence").load() <cr>]]))
    end
  end,
  priority = 100,
}
