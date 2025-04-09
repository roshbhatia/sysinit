return {
  -- Image preview with kitty/wezterm support
  {
    "samodostal/image.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    ft = { "png", "jpg", "jpeg", "gif", "bmp", "webp" },
    config = function()
      require("image").setup({
        render = {
          min_padding = 5,
          show_label = true,
        },
        events = {
          update_on_nvim_resize = true,
        },
      })
    end,
  },

  -- Git blame inline
  {
    "f-person/git-blame.nvim",
    event = "BufRead",
    config = function()
      require("gitblame").setup({
        enabled = false, -- Start disabled but toggleable
        date_format = "%r",
        message_template = "󰊤 <author> • <date> • <summary>",
        highlight_group = "LineNr",
        display_virtual_text = true,
        delay = 1000,
      })
      
      -- Add keybinding to toggle git blame
      vim.keymap.set("n", "<leader>gb", ":GitBlameToggle<CR>", { noremap = true, silent = true, desc = "󰊤 Toggle git blame" })
      
      -- Create an additional command to copy the commit hash
      vim.api.nvim_create_user_command("GitBlameCopyHash", function()
        local blame_info = require("gitblame").get_current_blame_info()
        if blame_info and blame_info.sha then
          vim.fn.setreg("+", blame_info.sha)
          print("Copied commit hash: " .. blame_info.sha)
        else
          print("No git blame info available")
        end
      end, {})
      
      -- Map copy hash command
      vim.keymap.set("n", "<leader>gB", ":GitBlameCopyHash<CR>", { noremap = true, silent = true, desc = "󰊤 Copy commit hash" })
    end,
  },

  -- Markdown preview with Glow
  {
    "ellisonleao/glow.nvim",
    cmd = "Glow",
    keys = {
      { "<leader>mp", "<cmd>Glow<CR>", desc = "󰍔 Toggle markdown preview" },
    },
    config = function()
      require('glow').setup({
        style = "dark",
        width = 120,
        height_ratio = 0.7,
        border = "rounded",
      })
    end,
  }
}