-- Configure image preview for WezTerm
local M = {}

M.setup = function()
  -- Check if in a terminal that supports images
  local is_wezterm = os.getenv("TERM_PROGRAM") == "WezTerm"
  local is_kitty = os.getenv("TERM") == "xterm-kitty"
  
  -- Auto detect supported terminals or allow explicit configuration
  local backend = "auto"
  if is_wezterm then
    backend = "wezterm"
  elseif is_kitty then
    backend = "kitty"
  end
  
  -- Add autocmd to handle image files
  vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
    pattern = {"*.png", "*.jpg", "*.jpeg", "*.bmp", "*.gif", "*.webp"},
    callback = function()
      -- Attempt to use image.nvim for display
      local image_ok, image = pcall(require, "image")
      if image_ok then
        -- Force display by default for WezTerm
        if is_wezterm then
          vim.defer_fn(function()
            -- Enable image display
            pcall(image.toggle, true) -- Force enable
            print("Image preview enabled with WezTerm backend")
          end, 100)
        else
          vim.defer_fn(function()
            print("Image preview ready (:ImageToggle to show/hide)")
          end, 100)
        end
      else
        -- Fallback message if image.nvim isn't available
        print("Image preview requires image.nvim plugin")
      end
    end
  })
  
  -- Add a command to toggle image preview
  vim.api.nvim_create_user_command("ImageToggle", function()
    local image_ok, image = pcall(require, "image")
    if image_ok then
      -- Toggle the image view
      pcall(image.toggle)
    else
      print("Image preview requires image.nvim plugin")
    end
  end, {})
  
  -- Map the command
  vim.keymap.set("n", "<leader>ti", ":ImageToggle<CR>", { noremap = true, silent = true, desc = "󰋩 Toggle image preview" })
end

return M