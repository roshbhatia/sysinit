return {
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
        buffer = {
          score_offset = 3,
          ---@diagnostic disable-next-line: unused-local
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = " Buffer "
              item.kind_name = "Buffer"
            end
            return items
          end,
        },
        lazydev = {
          enabled = false,
          module = "lazydev.integrations.blink",
          name = "LazyDev",
          score_offset = 1,
        },
        lsp = {
          score_offset = 0,
          ---@diagnostic disable-next-line: unused-local
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = "󰘧 LSP "
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
              item.kind_icon = " Path "
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
              item.kind_icon = "󰩫 Snippets "
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
              item.kind_icon = " Copilot "
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
              -- Close window if there's no documentation or detail to show
              local item = opts.item
              local has_detail = item and item.detail and item.detail ~= ""
              local has_doc = item and item.documentation

              if type(has_doc) == "table" then
                has_doc = has_doc.value and has_doc.value ~= ""
              elseif type(has_doc) == "string" then
                has_doc = has_doc ~= ""
              else
                has_doc = false
              end

              if not has_detail and not has_doc then
                opts.window:close()
                return
              end

              -- documentation can be either a string or a MarkupContent object per LSP spec
              -- only process when it's an object with a value field
              if
                item
                and item.documentation
                and type(item.documentation) == "table"
                and item.documentation.value
              then
                local out = require("pretty_hover.parser").parse(item.documentation.value)
                item.documentation.value = out:string()
              end
            end,
          },
          ghost_text = {
            enabled = true,
          },
          list = {
            selection = {
              preselect = false,
              auto_insert = false,
            },
          },
          menu = {
            max_height = 15,
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
    opts_extend = {
      "sources.default",
    },
  },
}
