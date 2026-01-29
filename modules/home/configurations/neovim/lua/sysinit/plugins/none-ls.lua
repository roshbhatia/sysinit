local function hex_color_generator()
  return {
    fn = function(context)
      local actions = {}

      local cursor = vim.api.nvim_win_get_cursor(0)
      local row, col = cursor[1] - 1, cursor[2]

      local function extract_hex_at_pos(line, start_col, end_col)
        local text = line:sub(start_col + 1, end_col)
        local hex_patterns = {
          "#%x%x%x%x%x%x%x%x",
          "#%x%x%x%x%x%x",
          "#%x%x%x",
        }

        for _, pattern in ipairs(hex_patterns) do
          local hex = text:match(pattern)
          if hex then
            return hex
          end
        end
        return nil
      end

      local function find_colorizer_hex()
        local ns_id = vim.api.nvim_get_namespaces()["colorizer"]
        if not ns_id then
          return nil
        end

        local extmarks = vim.api.nvim_buf_get_extmarks(
          context.bufnr,
          ns_id,
          { row, 0 },
          { row, -1 },
          { details = true }
        )

        for _, mark in ipairs(extmarks) do
          local mark_col = mark[3]
          local details = mark[4]

          if details and details.end_col then
            local start_col, end_col = mark_col, details.end_col
            if col >= start_col and col < end_col then
              local line = vim.api.nvim_buf_get_lines(context.bufnr, row, row + 1, false)[1]
              if line then
                return extract_hex_at_pos(line, start_col, end_col)
              end
            end
          end
        end
        return nil
      end

      local function find_string_hex()
        local line = vim.api.nvim_get_current_line()
        if not line then
          return nil
        end

        local quote_chars = { '"', "'", "`" }
        local in_string = false
        local string_start, string_end = nil, nil

        for _, quote in ipairs(quote_chars) do
          local start_pos = 1
          while true do
            local quote_start = line:find(quote, start_pos)
            if not quote_start then
              break
            end

            local quote_end = line:find(quote, quote_start + 1)
            if not quote_end then
              break
            end

            if col >= quote_start - 1 and col <= quote_end - 1 then
              string_start, string_end = quote_start, quote_end
              in_string = true
              break
            end

            start_pos = quote_end + 1
          end
          if in_string then
            break
          end
        end

        if in_string and string_start and string_end then
          return extract_hex_at_pos(line, string_start - 1, string_end)
        end

        return nil
      end

      local hex_color = find_colorizer_hex() or find_string_hex()

      if not hex_color then
        local word = vim.fn.expand("<cWORD>")
        if word then
          hex_color = extract_hex_at_pos(word, 0, #word)
        end
      end

      if hex_color then
        table.insert(actions, {
          title = "Copy hex color to clipboard",
          action = function()
            vim.fn.setreg("+", hex_color)
            vim.notify("Copied " .. hex_color .. " to clipboard")
          end,
        })

        table.insert(actions, {
          title = "Mutate hex color hue",
          action = function()
            vim.cmd("Huefy")
          end,
        })

        table.insert(actions, {
          title = "Generate hex color palette",
          action = function()
            vim.cmd("Shades")
          end,
        })
      end
      return actions
    end,
  }
end

local function open_link_generator()
  return {
    fn = function()
      local actions = {}
      local node = vim.treesitter.get_node()
      if not node then
        return actions
      end

      local text = vim.treesitter.get_node_text(node, 0)
      if not text then
        return actions
      end

      local url_pattern = "https?://[%w-_%.%?%.:/%+=&]+"
      local url = text:match(url_pattern)
      if url then
        table.insert(actions, {
          title = "Open link in browser",
          action = function()
            vim.fn.jobstart({ "open", url }, { detach = true })
          end,
        })
      end
      return actions
    end,
  }
end

return {
  {
    "nvimtools/none-ls.nvim",
    event = "LSPAttach",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local null_ls = require("null-ls")

      null_ls.setup({
        border = "rounded",
        debounce = 150,
        default_timeout = 5000,
        temp_dir = vim.fn.stdpath("cache") .. "/null-ls",
        sources = {
          null_ls.builtins.code_actions.gitrebase,
          null_ls.builtins.code_actions.impl,
          null_ls.builtins.code_actions.refactoring,
          null_ls.builtins.code_actions.statix,
          null_ls.builtins.code_actions.textlint,
          null_ls.builtins.diagnostics.actionlint,
          null_ls.builtins.diagnostics.checkmake,
          null_ls.builtins.diagnostics.deadnix,
          null_ls.builtins.diagnostics.golangci_lint,
          null_ls.builtins.diagnostics.kube_linter,
          null_ls.builtins.diagnostics.staticcheck,
          null_ls.builtins.diagnostics.terraform_validate,
          null_ls.builtins.diagnostics.tfsec,
          null_ls.builtins.diagnostics.zsh,
          null_ls.builtins.hover.dictionary,
          null_ls.builtins.hover.printenv,
        },
      })

      null_ls.register({
        name = "open_link_in_browser",
        method = null_ls.methods.CODE_ACTION,
        filetypes = {},
        generator = open_link_generator(),
      })

      null_ls.register({
        name = "hex_color_tools",
        method = null_ls.methods.CODE_ACTION,
        filetypes = {},
        generator = hex_color_generator(),
      })
    end,
  },
}
