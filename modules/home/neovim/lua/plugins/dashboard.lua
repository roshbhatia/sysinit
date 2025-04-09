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

      -- Set menu
      dashboard.section.buttons.val = {
        dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
        dashboard.button("f", "󰱼  Find file", ":Telescope find_files<CR>"),
        dashboard.button("r", "󰄉  Recent files", ":Telescope oldfiles<CR>"),
        dashboard.button("s", "󰒲  Settings", ":e $MYVIMRC<CR>"),
        dashboard.button("q", "󰗼  Quit", ":qa<CR>"),
      }

      -- Set footer
      dashboard.section.footer.val = "Welcome to Neovim!"

      alpha.setup(dashboard.opts)
    end,
  },
}
