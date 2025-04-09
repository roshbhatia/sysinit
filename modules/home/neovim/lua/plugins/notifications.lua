-- Notifications and messages configuration
return {
  -- Nvim-notify for nice notifications
  {
    "rcarriga/nvim-notify",
    lazy = false,
    priority = 90,  -- Load before noice
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
      background_colour = "#000000",
      render = "default",
      stages = "fade",
      top_down = true,
    },
    config = function(_, opts)
      local notify = require("notify")
      notify.setup(opts)
      vim.notify = notify
      
      -- Add keymappings for notification history
      vim.keymap.set("n", "<leader>nh", function()
        require("telescope").extensions.notify.notify()
      end, { desc = "Notification History" })
      
      -- Create a function to toggle notifications
      _G.toggle_notifications = function()
        if vim.g.notifications_enabled == false then
          vim.g.notifications_enabled = true
          vim.notify = notify
          vim.notify("Notifications enabled", "info", { title = "Notifications" })
        else
          vim.g.notifications_enabled = false
          vim.notify = function(...)
            -- Route to mini notification or do nothing
            local params = {...}
            local msg = params[1]
            local level = params[2]
            
            -- Still log errors to a log file even when notifications are disabled
            if level == "error" then
              -- Log to a file
              local log_file = vim.fn.stdpath("cache") .. "/nvim_errors.log"
              local file = io.open(log_file, "a")
              if file then
                file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. tostring(msg) .. "\n")
                file:close()
              end
            end
          end
          -- Use print instead of notify since notify is now disabled
          print("Notifications disabled")
        end
      end
      
      -- Initialize notifications as enabled
      vim.g.notifications_enabled = true
      
      -- Add keymapping to toggle notifications
      vim.keymap.set("n", "<leader>tn", function()
        _G.toggle_notifications()
      end, { desc = "Toggle Notifications" })
      
      -- Create a command to show error log
      vim.api.nvim_create_user_command("ErrorLog", function()
        local log_file = vim.fn.stdpath("cache") .. "/nvim_errors.log"
        if vim.fn.filereadable(log_file) == 1 then
          vim.cmd("vsplit " .. log_file)
        else
          vim.notify("No error log file found", "warn")
        end
      end, { desc = "Show error log file" })
      
      -- Add keymapping to show error log
      vim.keymap.set("n", "<leader>ne", "<cmd>ErrorLog<CR>", { desc = "Show Error Log" })
      
      -- Register with which-key if available
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.register({
          ["<leader>n"] = { name = "󰎟 Notifications" },
        })
      end
    end,
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
  },
  
  -- Noice UI for cmdline and messages
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
        hover = {
          enabled = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            kind = "",
            find = "written",
          },
          opts = { skip = true },
        },
        -- Store error and warning messages in a separate route
        {
          filter = {
            event = "msg_show",
            kind = { "error", "warn" },
          },
          view = "notify",
          opts = {
            title = "Errors and Warnings",
            replace = true,
            merge = true,
            timeout = 10000, -- Keep errors visible longer
          },
        },
        {
          filter = {
            event = "notify",
            min_height = 15,
          },
          view = "split",
          opts = { enter = true },
        },
      },
      commands = {
        -- Add :Noice errors command to show error history
        errors = {
          -- This grabs all error/warning notifications and puts them in a split
          filter = { error = true, warn = true },
          view = "split",
          opts = { enter = true, format = "details" },
        },
        -- Add all command to toggle noice completely
        toggle = {
          view = "notify",
          opts = { stop = true },
        },
        -- Clear notifications
        dismiss = {
          view = "notify",
          opts = { stop = true },
        },
      },
      views = {
        cmdline_popup = {
          position = {
            row = 5,
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
        },
        popupmenu = {
          relative = "editor",
          position = {
            row = 8,
            col = "50%",
          },
          size = {
            width = 60,
            height = 10,
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
          },
        },
        -- Customize the messages view
        messages = {
          view = "split",
          enter = true,
        },
      },
    },
    keys = {
      { "<leader>ne", "<cmd>Noice errors<cr>", desc = "Noice Error History" },
      { "<leader>nm", "<cmd>Noice messages<cr>", desc = "Noice Message History" },
      { "<leader>nd", "<cmd>Noice dismiss<cr>", desc = "Dismiss All Notifications" },
      
      -- Toggle Noice completely
      { "<leader>nt", function() 
          if vim.g.noice_enabled == false then
            vim.g.noice_enabled = true
            vim.cmd("Noice enable")
            vim.notify("Noice enabled", "info", { title = "Noice" })
          else
            vim.g.noice_enabled = false
            vim.cmd("Noice disable")
            print("Noice disabled")
          end
        end, 
        desc = "Toggle Noice UI" 
      },
    },
    init = function()
      -- Initialize Noice as enabled
      vim.g.noice_enabled = true
    end,
  },
  
  -- Add a trouble plugin to view all diagnostics in one place
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "TroubleToggle", "Trouble" },
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
      action_keys = {
        close = "q",
        cancel = "<esc>",
        refresh = "r",
        jump = {"<cr>", "<tab>"},
        open_split = {"<c-x>"},
        open_vsplit = {"<c-v>"},
        open_tab = {"<c-t>"},
        jump_close = {"o"},
        toggle_mode = "m",
        toggle_preview = "P",
        hover = "K",
        preview = "p",
        close_folds = {"zM", "zm"},
        open_folds = {"zR", "zr"},
        toggle_fold = {"zA", "za"},
        previous = "k",
        next = "j"
      },
      indent_lines = true,
      auto_open = false,
      auto_close = false,
      auto_preview = true,
      auto_fold = false,
      auto_jump = {"lsp_definitions"},
      signs = {
        error = "󰅙",
        warning = "󰀦",
        hint = "󰌵",
        information = "󰋼",
        other = "󰗡",
      },
      use_diagnostic_signs = true
    },
    keys = {
      { "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics (Trouble)" },
      { "<leader>xl", "<cmd>TroubleToggle loclist<cr>", desc = "Location List (Trouble)" },
      { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
      { "gR", "<cmd>TroubleToggle lsp_references<cr>", desc = "LSP References (Trouble)" },
    },
  },
}
