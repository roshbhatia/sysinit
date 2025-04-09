return {
  {
    "mrjones2014/legendary.nvim",
    priority = 10000, -- Load before other plugins
    lazy = false,
    dependencies = {
      "kkharji/sqlite.lua", -- Optional for frecency sorting
      "nvim-telescope/telescope.nvim", -- For fuzzy finder UI
      "stevearc/dressing.nvim", -- For enhanced UI
    },
    config = function()
      require("legendary").setup({
        keymaps = {
          { "<leader>ff", ":Telescope find_files<CR>", description = "Find files" },
          { "<leader>fg", ":Telescope live_grep<CR>", description = "Live grep" },
          { "<leader>fb", ":Telescope buffers<CR>", description = "Find buffers" },
          { "<leader>fh", ":Telescope help_tags<CR>", description = "Find help" },
        },
        commands = {
          {
            ":Legendary",
            description = "Open Legendary Command Palette",
          },
        },
        extensions = {
          lazy_nvim = true, -- Automatically load keymaps from lazy.nvim plugin specs
        },
        select_prompt = " Command Palette ",
      })
    end,
  },
}
