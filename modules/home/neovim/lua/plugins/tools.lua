-- Developer tools plugins

return {
  -- Telescope for fuzzy finding (plugin already defined in editor.lua, this is just for dependencies)
  {
    "nvim-telescope/telescope.nvim",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  
  -- Git client
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  
  -- Project tasks
  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerOpen",
      "OverseerToggle",
      "OverseerRun",
      "OverseerBuild",
      "OverseerClose",
      "OverseerInfo",
      "OverseerRunCmd",
    },
    keys = {
      { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Toggle Overseer" },
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run Task" },
      { "<leader>ob", "<cmd>OverseerBuild<cr>", desc = "Build" },
      { "<leader>oc", "<cmd>OverseerClose<cr>", desc = "Close" },
    },
    config = function()
      require("overseer").setup({
        task_list = {
          direction = "bottom",
          min_height = 10,
          max_height = 15,
          bindings = {
            ["<CR>"] = "RunAction",
            ["<C-e>"] = "Edit",
            ["<C-v>"] = "OpenVsplit",
            ["<C-s>"] = "OpenSplit",
            ["<C-t>"] = "OpenTab",
            ["<C-r>"] = "Restart",
            ["<C-c>"] = "Cancel",
            ["<C-l>"] = "Clear",
            ["<C-o>"] = "OpenOutputSplit",
          },
        },
        form = {
          border = "rounded",
          win_opts = {
            winblend = 0,
          },
        },
        confirm = {
          border = "rounded",
          win_opts = {
            winblend = 0,
          },
        },
        task_win = {
          border = "rounded",
          win_opts = {
            winblend = 0,
          },
        },
        templates = {
          "npm",
          "cargo",
          "make",
          "cmake",
          "go",
          "python",
        },
      })
    end,
  },
  
  -- Better quickfix with Trouble
  {
    "folke/trouble.nvim",
    cmd = { "TroubleToggle", "Trouble" },
    keys = {
      { "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics" },
      { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics" },
      { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List" },
      { "<leader>xl", "<cmd>TroubleToggle loclist<cr>", desc = "Location List" },
      { "<leader>xr", "<cmd>TroubleToggle lsp_references<cr>", desc = "LSP References" },
    },
    opts = {
      position = "bottom",
      height = 10,
      width = 50,
      icons = true,
      mode = "workspace_diagnostics",
      fold_open = "",
      fold_closed = "",
      group = true,
      padding = true,
      cycle_results = true,
      action_keys = {
        close = "q",
        cancel = "<esc>",
        refresh = "r",
        jump = { "<cr>", "<tab>" },
        open_split = { "<c-x>" },
        open_vsplit = { "<c-v>" },
        open_tab = { "<c-t>" },
        jump_close = { "o" },
        toggle_mode = "m",
        switch_severity = "s",
        toggle_preview = "P",
        hover = "K",
        preview = "p",
        close_folds = { "zM", "zm" },
        open_folds = { "zR", "zr" },
        toggle_fold = { "zA", "za" },
        previous = "k",
        next = "j",
      },
      indent_lines = true,
      auto_preview = true,
      signs = {
        error = "",
        warning = "",
        hint = "",
        information = "",
        other = "",
      },
      use_diagnostic_signs = true,
    },
  },
  
  -- Pasting from clipboard with formatting
  {
    "AckslD/nvim-FeMaco.lua",
    cmd = "FeMaco",
    keys = {
      { "<leader>mf", "<cmd>FeMaco<CR>", desc = "Edit Markdown Code Block" },
    },
    config = function()
      require("femaco").setup()
    end,
  },
  
  -- Markdown preview configuration
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreview<CR>", desc = "Markdown Preview" },
    },
    init = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_command_for_global = 0
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_open_ip = ""
      vim.g.mkdp_browser = ""
      vim.g.mkdp_echo_preview_url = 1
      vim.g.mkdp_browserfunc = ""
      vim.g.mkdp_markdown_css = ""
      vim.g.mkdp_highlight_css = ""
      vim.g.mkdp_port = ""
      vim.g.mkdp_page_title = "${name}"
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
    end,
  },
  
  -- Color highlighter
  {
    "norcalli/nvim-colorizer.lua",
    cmd = { "ColorizerToggle", "ColorizerAttachToBuffer", "ColorizerDetachFromBuffer", "ColorizerReloadAllBuffers" },
    keys = {
      { "<leader>tc", "<cmd>ColorizerToggle<CR>", desc = "Toggle Colorizer" },
    },
    config = function()
      require("colorizer").setup({
        "*",
        css = { css = true },
        html = { names = false },
      }, { mode = "background" })
    end,
  },
  
  -- Session manager
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
      options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
      pre_save = nil,
      save_empty = false,
    },
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },
  
  -- Improved Neovim UI
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        hover = {
          enabled = true,
        },
        signature = {
          enabled = true,
          auto_open = {
            enabled = true,
            trigger = true,
            luasnip = true,
            throttle = 50,
          },
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
      },
    },
  },
  
  -- Notification handler
  {
    "rcarriga/nvim-notify",
    keys = {
      {
        "<leader>un",
        function()
          require("notify").dismiss({ silent = true, pending = true })
        end,
        desc = "Dismiss all Notifications",
      },
    },
    opts = {
      timeout = 3000,
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.75)
      end,
      on_open = function(win)
        vim.api.nvim_win_set_config(win, { zindex = 100 })
      end,
    },
    init = function()
      -- When noice is not enabled, install notify as the UI for messages
      if not package.loaded["noice"] then
        vim.notify = require("notify")
      end
    end,
  },
}