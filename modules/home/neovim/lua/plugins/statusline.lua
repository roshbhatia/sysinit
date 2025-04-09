-- Sleek statusline with copilot integration
return {
  -- Lualine for advanced statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { 
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local lualine = require("lualine")
      
      -- Get Copilot status (check if loaded)
      local function get_copilot_status()
        local ok, copilot = pcall(require, "copilot.api")
        if not ok then
          return ""
        end
        
        -- Check if copilot is running
        local status = {
          enabled = copilot.enabled,
          busy = copilot.busy,
        }
        
        if not status.enabled then
          return " 󰶨"  -- Disabled
        elseif status.busy then
          return " 󰺄"  -- Processing
        else
          return " 󰚩"  -- Enabled
        end
      end
      
      -- Get Copilot Chat status (agent, model)
      local function get_copilot_chat_info()
        local ok, copilot_chat = pcall(require, "CopilotChat")
        if not ok then
          return ""
        end
        
        -- Try to get agent and model
        local agent = vim.g.copilot_chat_agent or "copilot"
        local model = vim.g.copilot_chat_model or "gpt-4o"
        
        -- Simplify model name
        model = model:gsub("gpt%-4o%-[0-9]+%-[0-9]+%-[0-9]+", "gpt-4o")
                     :gsub("gpt%-4%-[0-9]+", "gpt-4")
        
        return string.format(" %s ∙ %s", agent, model)
      end
      
      -- Get diagnostic information
      local function get_diagnostics()
        local diagnostics = vim.diagnostic.get(0)
        local count = {
          error = 0,
          warn = 0,
          info = 0,
          hint = 0,
        }
        
        for _, diagnostic in ipairs(diagnostics) do
          if diagnostic.severity == vim.diagnostic.severity.ERROR then
            count.error = count.error + 1
          elseif diagnostic.severity == vim.diagnostic.severity.WARN then
            count.warn = count.warn + 1
          elseif diagnostic.severity == vim.diagnostic.severity.INFO then
            count.info = count.info + 1
          elseif diagnostic.severity == vim.diagnostic.severity.HINT then
            count.hint = count.hint + 1
          end
        end
        
        local result = {}
        if count.error > 0 then
          table.insert(result, string.format(" %d", count.error))
        end
        if count.warn > 0 then
          table.insert(result, string.format(" %d", count.warn))
        end
        if count.info > 0 then
          table.insert(result, string.format(" %d", count.info))
        end
        if count.hint > 0 then
          table.insert(result, string.format(" %d", count.hint))
        end
        
        return table.concat(result, " ")
      end
      
      -- Mode configurations with different colors
      local mode_map = {
        ["NORMAL"] = { icon = "󰬄 ", color = "#7aa2f7" },
        ["INSERT"] = { icon = "󰲶 ", color = "#9ece6a" },
        ["VISUAL"] = { icon = "󰅤 ", color = "#bb9af7" },
        ["V-LINE"] = { icon = "󰅩 ", color = "#bb9af7" },
        ["V-BLOCK"] = { icon = "󰅦 ", color = "#bb9af7" },
        ["COMMAND"] = { icon = "󰘳 ", color = "#e0af68" },
        ["REPLACE"] = { icon = "󰛔 ", color = "#f7768e" },
        ["TERMINAL"] = { icon = "󰆍 ", color = "#7dcfff" },
        ["O-PENDING"] = { icon = "󰍉 ", color = "#73daca" },
        ["SELECT"] = { icon = "󰅪 ", color = "#bb9af7" },
      }
      
      -- Get colorful mode text
      local function get_mode()
        local mode = vim.api.nvim_get_mode().mode
        local mode_name = ""
        
        if mode == "n" then mode_name = "NORMAL"
        elseif mode == "i" then mode_name = "INSERT"
        elseif mode == "v" then mode_name = "VISUAL"
        elseif mode == "V" then mode_name = "V-LINE"
        elseif mode == "" then mode_name = "V-BLOCK"
        elseif mode == "c" then mode_name = "COMMAND"
        elseif mode == "R" then mode_name = "REPLACE"
        elseif mode == "t" then mode_name = "TERMINAL"
        elseif mode == "s" then mode_name = "SELECT"
        else mode_name = mode
        end
        
        local mode_data = mode_map[mode_name] or { icon = "󰄛 ", color = "#7aa2f7" }
        
        -- Set foreground color for the mode
        vim.api.nvim_set_hl(0, "LualineMode", { fg = mode_data.color, bold = true })
        
        return mode_data.icon
      end
      
      -- Get Git status
      local function get_git_status()
        local signs = vim.b.gitsigns_status_dict
        if not signs then
          return ""
        end
        
        local added = signs.added and signs.added > 0 and string.format(" %d", signs.added) or ""
        local changed = signs.changed and signs.changed > 0 and string.format(" %d", signs.changed) or ""
        local removed = signs.removed and signs.removed > 0 and string.format(" %d", signs.removed) or ""
        
        return table.concat({ added, changed, removed })
      end
      
      -- Get LSP status
      local function get_lsp_status()
        local buf_clients = vim.lsp.get_active_clients({ bufnr = 0 })
        if #buf_clients == 0 then
          return "󰒎 No LSP"
        end
        
        -- Get client names
        local client_names = {}
        for _, client in ipairs(buf_clients) do
          table.insert(client_names, client.name)
        end
        
        return string.format("󰒍 %s", table.concat(client_names, ", "))
      end
      
      -- Setup lualine
      lualine.setup({
        options = {
          icons_enabled = true,
          theme = "tokyonight",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = {
            statusline = { "dashboard", "alpha", "starter" },
            winbar = { "dashboard", "alpha", "starter" },
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = true,
          refresh = {
            statusline = 100,
            tabline = 100,
            winbar = 100,
          },
        },
        sections = {
          lualine_a = {
            { get_mode, color = { fg = "#1a1b26" }, separator = { right = "" } },
          },
          lualine_b = {
            { "branch", icon = "󰘬", color = { fg = "#7aa2f7", gui = "bold" } },
            { get_git_status, color = { fg = "#e0af68" } },
          },
          lualine_c = {
            { "filename", path = 1, shorting_target = 40, symbols = { modified = "󰛿 ", readonly = "󰌾 ", unnamed = "󰡯 " } },
            { get_diagnostics, color = { fg = "#f7768e" } },
          },
          lualine_x = {
            { get_lsp_status, color = { fg = "#7dcfff" } },
            { "filetype", icon_only = true, color = { fg = "#bb9af7" } },
            { get_copilot_status, color = { fg = "#9ece6a" } },
            { get_copilot_chat_info, color = { fg = "#9ece6a" } },
          },
          lualine_y = {
            { "progress", color = { fg = "#7aa2f7" } },
          },
          lualine_z = {
            { "location", icon = "󰧭", color = { fg = "#1a1b26", bg = "#7aa2f7" }, separator = { left = "" } },
          },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = { "nvim-tree", "toggleterm", "quickfix" },
      })
    end,
  },
  
  -- Highlight current line number
  {
    "mvllow/modes.nvim",
    event = "BufRead",
    config = function()
      require("modes").setup({
        colors = {
          copy = "#f1c40f",
          delete = "#c0392b",
          insert = "#9ece6a",
          visual = "#bb9af7",
        },
        line_opacity = 0.25,
        set_cursor = true,
        set_cursorline = true,
        set_number = true,
        ignore_filetypes = { "NvimTree", "TelescopePrompt" },
      })
    end,
  },
  
  -- Buffer tabs like VSCode
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local bufferline = require("bufferline")
      bufferline.setup({
        options = {
          mode = "buffers",
          indicator = {
            style = "underline",
          },
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(count, level)
            local icon = level:match("error") and " " or " "
            return " " .. icon .. count
          end,
          separator_style = "thin",
          show_buffer_close_icons = true,
          show_close_icon = true,
          enforce_regular_tabs = false,
          always_show_bufferline = true,
          sort_by = "id",
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              text_align = "center",
              separator = true,
            },
          },
        },
        highlights = {
          buffer_selected = {
            bold = true,
            italic = false,
          },
        },
      })
      
      -- Define keymaps for easier buffer navigation
      vim.keymap.set("n", "<leader>bp", "<cmd>BufferLinePick<CR>", { desc = "Pick buffer" })
      vim.keymap.set("n", "<leader>bc", "<cmd>BufferLinePickClose<CR>", { desc = "Close picked buffer" })
      vim.keymap.set("n", "<leader>bl", "<cmd>BufferLineCloseLeft<CR>", { desc = "Close buffers to the left" })
      vim.keymap.set("n", "<leader>br", "<cmd>BufferLineCloseRight<CR>", { desc = "Close buffers to the right" })
      vim.keymap.set("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Close other buffers" })
      vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
      vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
    end,
  },
}
