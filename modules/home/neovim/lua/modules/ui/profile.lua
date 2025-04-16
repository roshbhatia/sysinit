-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/Kurama622/profile.nvim/refs/heads/main/README.md"
local M = {}

M.plugins = {
  {
    "Kurama622/profile.nvim",
    dependencies = { "3rd/image.nvim" },
    lazy = true,  -- Lazy load since we only use it occasionally
    cmd = { "Profile" }, -- Load when Profile command is executed
    config = function()
      local comp = require("profile.components")
      local win_width = vim.o.columns
      
      -- Read the varre.ascii file and create a table of lines
      local varre_ascii_path = vim.fn.stdpath("config") .. "/varre.ascii"
      local varre_ascii = {}
      
      -- If the file exists, read it
      if vim.fn.filereadable(varre_ascii_path) == 1 then
        -- Read file content
        local content = vim.fn.readfile(varre_ascii_path)
        varre_ascii = content
      else
        -- Fallback ASCII art if file is not found
        varre_ascii = {
          [[                                                           ]],
          [[                     ....                                  ]],
          [[               .#-+##.. .. .+                             ]],
          [[            .####...         ...                          ]],
          [[           ##.##.+.       ..    +.                        ]],
          [[         .##.###..#       .  #-#...                       ]],
          [[         -## ####-...   .##.     ##                       ]],
          [[        .##. -######.  -.  .      #.                      ]],
          [[        ###..-# .##+####.....   ..-.                      ]],
          [[        ###  -#..#+###+##.####. #.#                       ]],
          [[       .###  ##..######.......# -.                        ]],
          [[       ####..##.#.#####.      #.  .                       ]],
          [[       ####.+##.#-.##.#.     ###...                       ]],
          [[      .###++-##..#.###...        .                        ]],
          [[      .###...##.#######..  .##+.+.                        ]],
          [[      .##....##..##.#####... .-.#.                        ]],
          [[      +#....##- .....#####-.   .# .                       ]],
          [[   ..#####+.##. .... .###########-..                      ]],
          [[   ########.### ..-...#+##########-..                     ]],
          [[  ########. ##.#+..#..+###########. #.                    ]],
          [[   .........###++#### .###############                    ]],
          [[            .+###-##+- .#############.#.                  ]],
          [[                  .################ .....                 ]],
          [[                    .####         .##.####                ]],
          [[                                                           ]],
        }
      end
      
      require("profile").setup({
        -- Avatar settings
        avatar_path = vim.fn.stdpath("config") .. "/static/profile.png", -- Will silently fail if not found
        avatar_opts = {
          avatar_width = 20,
          avatar_height = 20,
          avatar_x = math.floor((win_width - 20) / 2),
          avatar_y = 6,
          force_blank = true, -- Set to true to use ASCII art instead
        },
        
        -- Git user configuration
        user = "roshbhatia", -- Your GitHub username
        git_contributions = {
          start_week = 1,
          end_week = 40, -- Show up to 40 weeks
          empty_char = " ",
          full_char = { "▁", "▂", "▃", "▄", "█" },
          -- Cache settings for git contributions
          cache_path = vim.fn.stdpath("cache") .. "/profile.nvim/",
          cache_duration = 24 * 60 * 60, -- 1 day in seconds
        },
        
        -- UI settings
        hide = {
          statusline = true,
          tabline = true,
        },
        
        -- Keyboard settings
        disable_keys = { "h", "j", "k", "l", "<Left>", "<Right>", "<Up>", "<Down>", "<C-f>" },
        cursor_pos = { 0, 0 },  -- Top-left cursor position
        
        -- Format the dashboard content
        format = function()
          -- Use varre ASCII art
          for _, line in ipairs(varre_ascii) do
            comp:text_component_render({ comp:text_component(line, "center", "ProfileGreen") })
          end
          
          -- Header text
          comp:text_component_render({
            comp:text_component("Welcome back, Rosh", "center", "ProfileBlue"),
            comp:text_component("────────", "center", "ProfileGreen"),
          })
          comp:separator_render()
          
          -- Repository information
          comp:card_component_render({
            type = "table",
            content = function()
              return {
                {
                  title = "roshbhatia/sysinit",
                  description = [[Nix configuration for all of my machines
using flake.nix]],
                },
                {
                  title = "Your Recent Project",
                  description = [[Start from where you left off on
your important work]],
                },
              }
            end,
            hl = {
              border = "ProfileYellow",
              text = "ProfileYellow",
            },
          })
          comp:separator_render()
          
          -- Git contributions
          comp:git_contributions_render("ProfileGreen")
          
          -- Quick actions menu
          comp:text_component_render({
            comp:text_component("Quick Actions", "center", "ProfileBlue"),
            comp:text_component("────────", "center", "ProfileGreen"),
          })
          
          comp:card_component_render({
            type = "action",
            content = function()
              return {
                { key = "f", icon = " ", desc = "Find Files", action = "Telescope find_files" },
                { key = "r", icon = " ", desc = "Recent Files", action = "Telescope oldfiles" },
                { key = "g", icon = " ", desc = "Live Grep", action = "Telescope live_grep" },
                { key = "c", icon = " ", desc = "Configuration", action = "e $MYVIMRC" },
                { key = "t", icon = "󰉼 ", desc = "Change Theme", action = "Themify" },
                { key = "l", icon = "󰒲 ", desc = "Lazy", action = "Lazy" },
                { key = "q", icon = " ", desc = "Quit", action = "qa" },
              }
            end,
            hl = {
              border = "ProfileBlue",
              text = "ProfileBlue",
              action_text = "ProfileBlue", 
              action_key = "ProfileYellow",
            },
          })
        end,
      })
    end
  }
}

function M.setup()
  -- Register with which-key if available
  local status, wk = pcall(require, "which-key")
  if status then
    wk.register({
      ["<leader>P"] = { "<cmd>Profile<CR>", "Open Homepage" },
    })
  else
    -- Fallback mapping if which-key not available
    vim.api.nvim_set_keymap("n", "<leader>P", "<cmd>Profile<CR>", { silent = true })
  end
  
  -- Set up custom mappings in profile buffer
  local user_mappings = {
    n = {
      ["r"] = "<cmd>lua require('telescope.builtin').oldfiles()<cr>",
      ["f"] = "<cmd>lua require('telescope.builtin').find_files()<cr>",
      ["c"] = "<cmd>lua require('telescope.builtin').find_files({ cwd = vim.fn.stdpath('config') })<cr>",
      ["/"] = "<cmd>lua require('telescope.builtin').live_grep()<cr>",
      ["n"] = "<cmd>enew<cr>",
      ["l"] = "<cmd>Lazy<cr>",
      ["q"] = "<cmd>q<cr>",
      ["t"] = "<cmd>Themify<cr>",
    },
  }
  
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "profile",
    callback = function()
      for mode, mapping in pairs(user_mappings) do
        for key, cmd in pairs(mapping) do
          vim.api.nvim_buf_set_keymap(0, mode, key, cmd, { noremap = true, silent = true })
        end
      end
    end
  })
  
  -- Define highlight groups for profile.nvim
  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
      vim.api.nvim_set_hl(0, "ProfileBlue", { fg = "#61afef", bold = true })
      vim.api.nvim_set_hl(0, "ProfileGreen", { fg = "#98c379", bold = true })
      vim.api.nvim_set_hl(0, "ProfileYellow", { fg = "#e5c07b", bold = true })
      vim.api.nvim_set_hl(0, "ProfileRed", { fg = "#e06c75", bold = true })
    end
  })
end

return M
