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
            if not vim.tbl_contains(vim.api.nvim_list_wins(), alpha.window) then
              alpha.start()
            end
          else
            pcall(alpha.close)
          end
        end,
      })

      -- Prevent alpha from being scrollable
      vim.api.nvim_create_autocmd("WinScrolled", {
        callback = function()
          if vim.bo.filetype == "alpha" then
            vim.cmd("normal! gg") -- Reset scroll to the top
          end
        end,
      })

      -- Fix invalid buffer ID error during WinResized
      vim.api.nvim_create_autocmd("WinResized", {
        callback = function()
          if vim.bo.filetype == "alpha" and vim.api.nvim_buf_is_valid(0) then
            pcall(alpha.redraw)
          end
        end,
      })
    end,
  },
}
