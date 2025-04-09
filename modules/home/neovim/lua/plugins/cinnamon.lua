-- Smooth scrolling plugin configuration
return {
  "declancm/cinnamon.nvim",
  version = "*", -- use latest release
  event = "VeryLazy",
  config = function()
    require("cinnamon").setup({
      -- Default options
      disabled = false,
      
      keymaps = {
        -- Enable the provided keymaps
        basic = true,  -- Half-window movements, page movements, search results
        extra = true,  -- Start/end of file, line numbers, line start/end, all scrolling
      },
      
      options = {
        -- Use cursor mode by default for smoother experience
        mode = "cursor",
        
        -- Only animate if a count is provided
        count_only = false,
        
        -- Delay between each movement step (in ms) - lower = faster
        delay = 5,
        
        max_delta = {
          -- Maximum line movement distance before skipping animation
          line = 500,
          -- Maximum column movement distance before skipping animation
          column = 80,
          -- Maximum duration for a movement in milliseconds
          time = 250,  -- Short animation time for responsiveness
        },
        
        step_size = {
          -- Lines moved per step
          vertical = 4,  -- Faster vertical scrolling
          -- Columns moved per step
          horizontal = 8,  -- Faster horizontal scrolling
        },
        
        -- Optional post-movement callback
        callback = function() end,
      },
    })
    
    -- Additional keymaps for centered scrolling with smooth animation
    vim.keymap.set("n", "<C-u>", function() require("cinnamon").scroll("<C-u>zz") end, 
                  { desc = "󰜸 Smooth half-page up centered" })
    vim.keymap.set("n", "<C-d>", function() require("cinnamon").scroll("<C-d>zz") end, 
                  { desc = "󰜮 Smooth half-page down centered" })
    
    -- LSP integration with smooth scrolling
    vim.keymap.set("n", "gd", function() require("cinnamon").scroll(vim.lsp.buf.definition) end, 
                  { desc = "󰞙 Go to definition (smooth)" })
    vim.keymap.set("n", "gD", function() require("cinnamon").scroll(vim.lsp.buf.declaration) end, 
                  { desc = "󰞙 Go to declaration (smooth)" })
    
    -- Disable for specific filetypes
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "help", "NvimTree", "lazy", "mason" },
      callback = function() vim.b.cinnamon_disable = true end,
    })
  end,
}