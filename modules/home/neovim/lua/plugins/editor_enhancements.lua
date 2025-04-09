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

  -- Markdown preview 
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "󰍔 Toggle markdown preview" },
    },
    config = function()
      vim.g.mkdp_auto_start = 1  -- Auto-open preview when entering markdown buffer
      vim.g.mkdp_auto_close = 0  -- Don't auto-close preview when leaving markdown buffer
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_command_for_global = 0
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_open_ip = ""
      vim.g.mkdp_browser = ""
      vim.g.mkdp_echo_preview_url = 0
      vim.g.mkdp_browserfunc = ""
      vim.g.mkdp_preview_options = {
        mkit = {},
        katex = {},
        uml = {},
        maid = {},
        disable_sync_scroll = 0,
        sync_scroll_type = "middle",
        hide_yaml_meta = 1,
        sequence_diagrams = {},
        flowchart_diagrams = {},
        content_editable = false,
        disable_filename = 0,
        toc = {}
      }
      vim.g.mkdp_markdown_css = ""
      vim.g.mkdp_highlight_css = ""
      vim.g.mkdp_port = ""
      vim.g.mkdp_page_title = "${name}"
      vim.g.mkdp_filetypes = {"markdown"}
      vim.g.mkdp_theme = "dark"
      vim.g.mkdp_position = "right"  -- Position preview on the right
      
      -- Auto-open markdown preview on markdown files
      vim.api.nvim_create_autocmd({"FileType"}, {
        pattern = "markdown",
        callback = function()
          vim.defer_fn(function()
            vim.cmd("MarkdownPreview")
          end, 100)
        end,
      })
    end,
  }
}