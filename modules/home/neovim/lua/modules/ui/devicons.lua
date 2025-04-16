-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/nvim-tree/nvim-web-devicons/refs/heads/master/README.md"
local M = {}

M.plugins = {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    config = function()
      require("nvim-web-devicons").setup({
        override = {
          default_icon = {
            icon = "",
            color = "#6d8086",
            name = "Default",
          },
          nix = {
            icon = "",
            color = "#7ebae4",
            name = "Nix",
          },
        },
        default = true,
        strict = true,
        color_icons = true,
      })
    end
  }
}

function M.setup()
  local status, wk = pcall(require, "which-key")
  if status then
    wk.register({
      ["<leader>i"] = {
        name = "🎨 Icons",
        s = { 
          function()
            local icons_status, icons = pcall(require, 'nvim-web-devicons')
            if not icons_status then
              vim.notify("nvim-web-devicons not available", vim.log.levels.ERROR)
              return
            end
            
            local all_icons = icons.get_icons()
            if all_icons then
              vim.api.nvim_echo({{vim.inspect(all_icons), "Normal"}}, true, {})
            else
              vim.notify("No icons available", vim.log.levels.WARN)
            end
          end,
          "Show All DevIcons"
        },
      },
    })
  end
  
  vim.api.nvim_create_user_command("ShowDevIcons", function()
    local icons_status, icons = pcall(require, 'nvim-web-devicons')
    if not icons_status then
      vim.notify("nvim-web-devicons not available", vim.log.levels.ERROR)
      return
    end
    
    local all_icons = icons.get_icons()
    if all_icons then
      vim.api.nvim_echo({{vim.inspect(all_icons), "Normal"}}, true, {})
    else
      vim.notify("No icons available", vim.log.levels.WARN)
    end
  end, {})
end

return M
