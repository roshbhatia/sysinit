local M = {}

M.plugins = {
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    priority = 1000,
    dependencies = {
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
      "xzbdmw/colorful-menu.nvim",
      "neovim/nvim-lspconfig",
      "fang2hou/blink-copilot",
      "copilotlsp-nvim/copilot-lsp",
    },
    opts = function()
      local providers = {
        ai_placeholders = {
          name = "AI Placeholders",
          module = "sysinit.plugins.intellicode.ai.completion",
          score_offset = 10,
          ---@diagnostic disable-next-line: unused-local
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = "󱚞 "
              item.kind_name = "AI"
            end
            return items
          end,
        },
        buffer = {
          score_offset = 3,
          ---@diagnostic disable-next-line: unused-local
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = " "
              item.kind_name = "Buffer"
            end
            return items
          end,
        },
        lazydev = {
          enabled = function()
            return vim.tbl_contains({ "lua" }, vim.bo.filetype)
          end,
          module = "lazydev.integrations.blink",
          name = "LazyDev",
          score_offset = 1,
        },
        lsp = {
          score_offset = 0,
          ---@diagnostic disable-next-line: unused-local
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = "󰘧 "
              item.kind_name = "LSP"
            end
            return items
          end,
        },
        path = {
          score_offset = 1,
          ---@diagnostic disable-next-line: unused-local
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = " "
              item.kind_name = "Path"
            end
            return items
          end,
          opts = {
            show_hidden_files_by_default = true,
          },
        },
        snippets = {
          score_offset = 2,
          ---@diagnostic disable-next-line: unused-local
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = "󰩫 "
              item.kind_name = "Snippets"
            end
            return items
          end,
        },
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
          ---@diagnostic disable-next-line: unused-local
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = " "
              item.kind_name = "Copilot"
            end
            return items
          end,
        },
        orgmode = {
          name = "Orgmode",
          module = "orgmode.org.autocompletion.blink",
          fallbacks = { "buffer" },
        },
      }

      local sources = {
        "buffer",
        "lazydev",
        "lsp",
        "path",
        "snippets",
        "copilot",
        per_filetype = {
          org = { "orgmode" },
          ai_terminals_input = { "ai_placeholders", "lsp", "path" },
        },
      }

      return {
        completion = {
          accept = {
            auto_brackets = {
              enabled = false,
            },
            create_undo_point = true,
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 0,
            window = {
              border = "rounded",
            },
            draw = function(opts)
              if opts.item and opts.item.documentation then
                local doc = opts.item.documentation
                local doc_value = type(doc) == "string" and doc or (doc.value or "")
                local out = require("pretty_hover.parser").parse(doc_value)

                if type(doc) == "string" then
                  opts.item.documentation = out:string()
                else
                  opts.item.documentation.value = out:string()
                end
              end

              opts.default_implementation(opts)
            end,
          },
          ghost_text = {
            enabled = true,
          },
          list = {
            selection = {
              preselect = true,
              auto_insert = false,
            },
          },
          menu = {
            border = "rounded",
            draw = {
              columns = {
                {
                  "kind_icon",
                },
                {
                  "label",
                  gap = 1,
                },
              },
              components = {
                label = {
                  text = function(ctx)
                    return require("colorful-menu").blink_components_text(ctx)
                  end,
                  highlight = function(ctx)
                    return require("colorful-menu").blink_components_highlight(ctx)
                  end,
                },
              },
              treesitter = {
                "lsp",
                "copilot",
              },
            },
          },
        },
        cmdline = {
          enabled = false,
        },
        fuzzy = {
          implementation = "prefer_rust",
        },
        keymap = {
          preset = "super-tab",
          ["<C-Space>"] = {
            "show",
          },
          ["<CR>"] = {
            "accept",
            "fallback",
          },
          ["<Tab>"] = {
            function(cmp)
              local ok, copilot = pcall(require, "blink-copilot")
              if ok and copilot.is_visible and copilot.is_visible() then
                return cmp.select_and_accept()
              end
            end,
            "select_next",
            "snippet_forward",
            "fallback",
          },
          ["<S-Tab>"] = {
            "select_prev",
            "snippet_backward",
            "fallback",
          },
        },
        signature = {
          enabled = true,
          window = {
            border = "rounded",
          },
        },
        sources = {
          default = sources,
          providers = providers,
        },
        snippets = {
          preset = "luasnip",
        },
      }
    end,
    config = function(_, opts)
      require("blink.cmp").setup(opts)
      vim.defer_fn(function()
        require("sysinit.plugins.intellicode.ai.completion").setup()
      end, 100)
    end,
    opts_extend = {
      "sources.default",
    },
  },
}

return M
