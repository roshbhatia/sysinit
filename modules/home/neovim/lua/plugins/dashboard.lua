return {
  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      -- Load ASCII art from file
      local ascii_path = "/Users/rbha27/github/personal/roshbhatia/sysinit/modules/home/neovim/lua/plugins/assets/ascii.txt"
      local ascii_art = {}
      for line in io.lines(ascii_path) do
        table.insert(ascii_art, line)
      end

      -- Set header (ASCII art)
      dashboard.section.header.val = ascii_art

      -- Remove menu and footer
      dashboard.section.buttons.val = {}
      dashboard.section.footer.val = ""

      -- Make the ASCII art transparent and static
      vim.cmd([[
        hi AlphaHeader guibg=NONE
        setlocal noscrollbind
        setlocal nolist
        setlocal nowrap
      ]])

      alpha.setup(dashboard.opts)

      -- Autocommand to show alpha when no files are open
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        callback = function()
          if #vim.fn.getbufinfo({ buflisted = true }) == 0 then
            alpha.start()
          else
            pcall(alpha.close)
          end
        end,
      })
    end,
  },
}
