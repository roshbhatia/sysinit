-- Enhanced editor experience (like VSCode)
return {
  -- Match and highlight brackets
  {
    "andymass/vim-matchup",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
      vim.g.matchup_surround_enabled = 1
      vim.g.matchup_motion_enabled = 1
      vim.g.matchup_text_obj_enabled = 1
    end,
  },
  
  -- Enhanced multi-cursor support
  {
    "mg979/vim-visual-multi",
    event = "BufReadPost",
    init = function()
      vim.g.VM_leader = '\\'
      vim.g.VM_maps = {
        ["Find Under"] = '<C-d>',
        ["Find Subword Under"] = '<C-d>',
      }
    end,
  },
  
  -- Highlight active indentation
  {
    "echasnovski/mini.indentscope",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      symbol = "│",
      options = { try_as_border = true },
      draw = {
        animation = function(s, n) return 5 end
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy",
          "mason", "notify", "toggleterm", "lazyterm",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },
  
  -- Automatic bracket and tag completion
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  }
}
