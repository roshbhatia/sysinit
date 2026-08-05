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
          "#%x%x%x%x",
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

      local function find_hipatterns_hex()
        local ok, hipatterns = pcall(require, "mini.hipatterns")
        if not ok or type(hipatterns.get_matches) ~= "function" then
          return nil
        end

        local ok_matches, matches = pcall(hipatterns.get_matches, context.bufnr, {
          "hex_color",
          "hex_color_short",
          "hex_color_short_alpha",
          "hex_color_alpha",
        })
        if not ok_matches or type(matches) ~= "table" then
          return nil
        end

        local line = vim.api.nvim_buf_get_lines(context.bufnr, row, row + 1, false)[1]
        if not line then
          return nil
        end

        local cursor_col = col + 1
        for _, match in ipairs(matches) do
          if match.lnum == row + 1 and type(match.col) == "number" and type(match.end_col) == "number" then
            if cursor_col >= match.col and cursor_col < match.end_col then
              local hex_text = line:sub(match.col, match.end_col - 1)
              local hex = extract_hex_at_pos(hex_text, 0, #hex_text)
              if hex then
                return hex
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

      local hex_color = find_hipatterns_hex() or find_string_hex()

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
    init = function()
      vim.o.formatexpr = "v:lua.vim.lsp.formatexpr()"

      if vim.g.disable_autoformat == nil then
        vim.g.disable_autoformat = false
      end

      vim.api.nvim_create_user_command("Format", function(args)
        local range = nil
        if args.count ~= -1 then
          local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
          }
        end
        vim.lsp.buf.format({ async = true, range = range })
      end, { range = true, desc = "Format buffer or range" })

      vim.api.nvim_create_user_command("FormatDisable", function()
        vim.g.disable_autoformat = true
      end, { desc = "Disable autoformat-on-save globally" })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.g.disable_autoformat = false
      end, { desc = "Re-enable autoformat-on-save globally" })

      vim.api.nvim_create_user_command("FormatBufDisable", function()
        vim.b.disable_autoformat = true
      end, { desc = "Disable autoformat-on-save for buffer" })

      vim.api.nvim_create_user_command("FormatBufEnable", function()
        vim.b.disable_autoformat = false
      end, { desc = "Re-enable autoformat-on-save for buffer" })

      vim.api.nvim_create_user_command("FormatStatus", function()
        local global = vim.g.disable_autoformat and "disabled" or "enabled"
        local buffer = vim.b.disable_autoformat and "disabled" or "enabled"
        vim.notify(string.format("Autoformat: global=%s, buffer=%s", global, buffer), vim.log.levels.INFO)
      end, { desc = "Show autoformat status" })
    end,
    config = function()
      local null_ls = require("null-ls")

      null_ls.setup({
        debounce = 150,
        default_timeout = 5000,
        temp_dir = vim.fn.stdpath("cache") .. "/null-ls",
        sources = {
          -- Code actions
          null_ls.builtins.code_actions.gitrebase,
          null_ls.builtins.code_actions.gitsigns,
          null_ls.builtins.code_actions.gomodifytags,
          null_ls.builtins.code_actions.impl,
          null_ls.builtins.code_actions.statix,
          null_ls.builtins.code_actions.textlint,
          null_ls.builtins.code_actions.ts_node_action,

          -- Diagnostics
          null_ls.builtins.diagnostics.actionlint,
          null_ls.builtins.diagnostics.checkmake,
          null_ls.builtins.diagnostics.commitlint,
          null_ls.builtins.diagnostics.deadnix,
          null_ls.builtins.diagnostics.kube_linter,
          null_ls.builtins.diagnostics.staticcheck,
          null_ls.builtins.diagnostics.statix,
          null_ls.builtins.diagnostics.terraform_validate,
          null_ls.builtins.diagnostics.tfsec,
          null_ls.builtins.diagnostics.zsh,

          -- Hover
          null_ls.builtins.hover.dictionary,
          null_ls.builtins.hover.printenv,

          -- Formatting (only tools without a capable LSP counterpart)
          -- gopls handles Go, nixd handles Nix, terraformls handles Terraform
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.prettier.with({
            filetypes = {
              "javascript",
              "typescript",
              "javascriptreact",
              "typescriptreact",
              "json",
              "jsonc",
              "yaml",
              "html",
              "css",
              "scss",
              "less",
              "markdown",
            },
          }),
          null_ls.builtins.formatting.shfmt.with({
            filetypes = { "sh", "bash", "zsh" },
          }),
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

      -- When multiple native LSP formatters cover the same filetype, pick the first attached
      -- one from this table rather than prompting. null-ls always wins when it has a source.
      local formatter_priority = {
        nix = { "nixd", "nil_ls" },
      }

      local augroup = vim.api.nvim_create_augroup("NullLsFormatting", { clear = true })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        callback = function(args)
          local bufnr = args.buf
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          if require("neoconf").get("autoformat", nil, { bufnr = bufnr }) == false then
            return
          end
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
          if ok and stats and stats.size and stats.size > 1024 * 1024 then
            return
          end

          local ft = vim.bo[bufnr].filetype
          -- null-ls is only preferred when it actually has a formatter for this filetype.
          -- Without this check, filetypes like nix get silently swallowed: null-ls is
          -- attached (for diagnostics/code-actions) but has no formatter, so native LSPs
          -- (nixd, nil_ls) are incorrectly skipped.
          local has_null_ls_formatter = #require("null-ls.sources").get_available(
            ft,
            null_ls.methods.FORMATTING
          ) > 0
          local use_null_ls = has_null_ls_formatter
            and #vim.lsp.get_clients({ bufnr = bufnr, name = "null-ls" }) > 0

          -- For filetypes with multiple native formatters, pick the highest-priority one
          -- that is currently attached (silently falls through to the next if absent).
          local chosen_lsp = nil
          if not use_null_ls then
            local priority = formatter_priority[ft]
            if priority then
              local attached = {}
              for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
                if c.server_capabilities and c.server_capabilities.documentFormattingProvider then
                  attached[c.name] = true
                end
              end
              for _, name in ipairs(priority) do
                if attached[name] then
                  chosen_lsp = name
                  break
                end
              end
            end
          end

          vim.lsp.buf.format({
            bufnr = bufnr,
            async = false,
            filter = function(client)
              if client.name == "null-ls" then return use_null_ls end
              if use_null_ls then return false end
              if chosen_lsp then return client.name == chosen_lsp end
              return true
            end,
          })
        end,
      })
    end,
  },
}
