local M = {}

-- Define module dependencies
M.depends_on = { "core" }

-- Track registered keymaps by context/mode
M.keymaps = {
  global = {},
  modes = {},
  contexts = {},
}

M.plugins = {
  {
    "mrjones2014/legendary.nvim",
    priority = 10000,
    lazy = false,
    dependencies = { "folke/which-key.nvim" },
    opts = function()
      -- Get all keymaps from our own system
      local keymaps = M.get_all_keymaps()
      
      return {
        extensions = {
          which_key = {
            auto_register = true,
            do_binding = true,
            use_groups = true,
            mappings = M.get_which_key_mappings(),
          },
          lazy_nvim = true,
        },
        keymaps = keymaps,
        commands = {
          { ":KM", function() M.show_context_keymaps() end, description = "Show Context Keymaps" },
        },
        autocmds = {
          -- Check for context changes to update keymaps
          {
            { "BufEnter", "FileType" },
            function()
              M.update_context_keymaps()
            end
          }
        }
      }
    end,
  },
  
  -- Hydra for modal interfaces
  {
    "anuvyklack/hydra.nvim",
    lazy = true,
    opts = {},
  },
}

-- API for registering keymaps

-- Register a global keymap
function M.register_keymap(lhs, rhs, opts)
  opts = opts or {}
  opts.mode = opts.mode or "n"
  opts.description = opts.description or ""
  
  local keymap = {
    lhs = lhs,
    rhs = rhs,
    opts = opts,
    description = opts.description,
    mode = opts.mode,
  }
  
  -- Store in our registry
  if not M.keymaps.global[opts.mode] then
    M.keymaps.global[opts.mode] = {}
  end
  table.insert(M.keymaps.global[opts.mode], keymap)
  
  return keymap
end

-- Register a mode-specific keymap
function M.register_mode_keymap(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.mode = mode
  opts.description = opts.description or ""
  
  local keymap = {
    lhs = lhs, 
    rhs = rhs,
    opts = opts,
    description = opts.description,
    mode = mode,
  }
  
  -- Store in mode-specific registry
  if not M.keymaps.modes[mode] then
    M.keymaps.modes[mode] = {}
  end
  table.insert(M.keymaps.modes[mode], keymap)
  
  return keymap
end

-- Register a context-aware keymap
function M.register_context_keymap(context, lhs, rhs, opts)
  opts = opts or {}
  opts.mode = opts.mode or "n"
  opts.description = opts.description or ""
  
  local keymap = {
    lhs = lhs,
    rhs = rhs,
    opts = opts,
    description = opts.description,
    mode = opts.mode,
    context = context,
  }
  
  -- Store by context
  if not M.keymaps.contexts[context] then
    M.keymaps.contexts[context] = {}
  end
  if not M.keymaps.contexts[context][opts.mode] then
    M.keymaps.contexts[context][opts.mode] = {}
  end
  table.insert(M.keymaps.contexts[context][opts.mode], keymap)
  
  return keymap
end

-- Define a Hydra modal keymap
function M.define_hydra(name, opts)
  local hydra = require('hydra')
  
  -- Register the hydra 
  local heads = {}
  for _, mapping in ipairs(opts.mappings) do
    table.insert(heads, {
      mapping[1], -- key
      mapping[2], -- command
      { desc = mapping[3] } -- description
    })
  end
  
  hydra({
    name = name,
    mode = opts.mode or 'n',
    body = opts.prefix,
    heads = heads,
    config = {
      color = opts.color or 'red',
      invoke_on_body = true,
      hint = {
        position = opts.hint_position or 'bottom',
        border = opts.hint_border or 'rounded'
      },
    }
  })
  
  -- Register entry point keymap
  M.register_keymap(opts.prefix, function() end, {
    description = "Enter " .. name .. " Mode",
    mode = opts.mode or "n"
  })
end

-- Update context-aware keymaps based on current buffer
function M.update_context_keymaps()
  -- Clear previous context keymaps
  local clear_keymaps = {}
  for _, mode_maps in pairs(M.keymaps.modes) do
    for _, keymap in ipairs(mode_maps) do
      if keymap._active then
        table.insert(clear_keymaps, keymap)
      end
    end
  end
  
  for _, keymap in ipairs(clear_keymaps) do
    pcall(vim.keymap.del, keymap.mode, keymap.lhs)
    keymap._active = false
  end
  
  -- Determine current context
  local ft = vim.bo.filetype
  local ctx = { ft = ft }
  
  -- Apply keymaps for current context
  if M.keymaps.contexts[ft] then
    for mode, maps in pairs(M.keymaps.contexts[ft]) do
      for _, keymap in ipairs(maps) do
        -- Check if any condition function exists
        if not keymap.condition or keymap.condition(ctx) then
          vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs, keymap.opts)
          keymap._active = true
        end
      end
    end
  end
  
  -- Apply mode-specific keymaps
  local current_mode = vim.fn.mode()
  if M.keymaps.modes[current_mode] then
    for _, keymap in ipairs(M.keymaps.modes[current_mode]) do
      vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs, keymap.opts)
      keymap._active = true
    end
  end
  
  -- Notify legendary to refresh
  local legendary_loaded, legendary = pcall(require, "legendary")
  if legendary_loaded then
    legendary.refresh()
  end
end

-- Get all registered keymaps for legendary
function M.get_all_keymaps()
  local all_keymaps = {}
  
  -- Global keymaps
  for mode, keymaps in pairs(M.keymaps.global) do
    for _, keymap in ipairs(keymaps) do
      table.insert(all_keymaps, {
        keymap.lhs,
        keymap.rhs,
        description = keymap.description,
        mode = keymap.mode
      })
    end
  end
  
  -- We don't include context-specific keymaps here
  -- They're dynamically loaded by update_context_keymaps
  
  -- Add default keymaps if empty
  if #all_keymaps == 0 then
    all_keymaps = {
      -- Basic operations
      { "<leader>w", "<cmd>write<CR>", description = "Save File" },
      { "<leader>q", "<cmd>quit<CR>", description = "Quit" },
      
      -- Panel groups
      { "<leader>e", description = "Explorer" },
      { "<leader>r", description = "Right Panel" },
      { "<leader>w", description = "Window" },
    }
  end
  
  return all_keymaps
end

-- Convert our keymaps to which-key format
function M.get_which_key_mappings()
  local mappings = { 
    mode = { n = {} }
  }
  
  -- Helper to add to which-key structure
  local function add_to_which_key(mode, lhs, mapping)
    if not mappings.mode[mode] then
      mappings.mode[mode] = {}
    end
    
    -- Handle group prefix
    if lhs:match("^<leader>%a$") then
      local key = lhs:sub(-1)
      if type(mapping) == "string" then
        mappings.mode[mode][key] = { name = mapping }
      else
        mappings.mode[mode][key] = mapping
      end
    else
      -- Handle complex key sequences
      local parts = {}
      for c in lhs:gmatch("[^<>]+") do
        if c ~= "leader" then
          table.insert(parts, c)
        end
      end
      
      if #parts > 0 and lhs:match("^<leader>") then
        local key = table.remove(parts, 1)
        
        -- Ensure this key exists in the mappings
        if not mappings.mode[mode][key] then
          mappings.mode[mode][key] = { name = "+" }
        end
        
        -- Navigate to the right location
        local current = mappings.mode[mode][key]
        for i = 1, #parts - 1 do
          local part = parts[i]
          if not current[part] then
            current[part] = { name = "+" }
          end
          current = current[part]
        end
        
        -- Set the leaf mapping
        if #parts > 0 then
          current[parts[#parts]] = mapping
        end
      end
    end
  end
  
  -- Process all global keymaps
  for mode, keymaps in pairs(M.keymaps.global) do
    for _, keymap in ipairs(keymaps) do
      -- Skip if no leader prefix
      if keymap.lhs:match("^<leader>") then
        add_to_which_key(mode, keymap.lhs, {
          [keymap.lhs] = { keymap.rhs, keymap.description }
        })
      end
    end
  end
  
  return mappings
end

-- Show active context keymaps
function M.show_context_keymaps()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  
  local ft = vim.bo.filetype
  local lines = {
    "Context Keymaps for " .. ft,
    "========================",
    ""
  }
  
  if M.keymaps.contexts[ft] then
    for mode, maps in pairs(M.keymaps.contexts[ft]) do
      table.insert(lines, "Mode: " .. mode)
      for _, keymap in ipairs(maps) do
        local active = keymap._active and "[Active]" or "[Inactive]"
        table.insert(lines, string.format("  %s %s -> %s (%s)", 
          active, keymap.lhs, 
          type(keymap.rhs) == "function" and "<function>" or keymap.rhs,
          keymap.description
        ))
      end
      table.insert(lines, "")
    end
  else
    table.insert(lines, "No context keymaps defined for " .. ft)
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Show in split
  vim.cmd("botright split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, math.min(#lines, 15))
  
  -- Close with q
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
end

-- Add test cases
local test = require("core.test")
test.register_test("keybindings", function()
  local tests = {
    function()
      print("Testing global keymap registration...")
      local orig_count = #M.get_all_keymaps()
      M.register_keymap("<leader>tk", "<cmd>echo 'Test'<CR>", { description = "Test Keymap" })
      local new_count = #M.get_all_keymaps()
      assert(new_count > orig_count, "Keymap should be registered")
      return true, "Global keymap registration works"
    end,
    
    function()
      print("Testing context keymap registration...")
      local ft = "lua"
      local orig_count = M.keymaps.contexts[ft] and #M.keymaps.contexts[ft].n or 0
      M.register_context_keymap(ft, "<leader>tl", "<cmd>echo 'Test Lua'<CR>", { description = "Test Lua Keymap" })
      local new_count = #M.keymaps.contexts[ft].n
      assert(new_count > orig_count, "Context keymap should be registered")
      return true, "Context keymap registration works"
    end
  }
  
  for i, test_fn in ipairs(tests) do
    local success, msg = pcall(test_fn)
    if not success then
      return false, "Test " .. i .. " failed: " .. msg
    end
  end
  
  return true, "All keybinding tests passed"
end)

-- Add verification steps
local verify = require("core.verify")
verify.register_verification("keybindings", {
  {
    desc = "Check Legendary integration",
    command = ":Legendary",
    expected = "Should open command palette with all registered keymaps",
  },
  {
    desc = "Verify Which-Key integration",
    command = "Press <leader> and wait",
    expected = "Should show which-key popup with all registered keymaps",
  },
  {
    desc = "Test context keymaps",
    command = ":KM",
    expected = "Should show context-specific keymaps for current buffer",
  },
})

function M.setup()
  -- Register default keymaps
  M.register_keymap("<leader>w", "<cmd>write<CR>", { description = "Save File" })
  M.register_keymap("<leader>q", "<cmd>quit<CR>", { description = "Quit" })
  
  -- Register group prefixes for which-key
  M.register_keymap("<leader>e", nil, { description = "Explorer" })
  M.register_keymap("<leader>r", nil, { description = "Right Panel" })
  M.register_keymap("<leader>f", nil, { description = "Find/Files" })
  M.register_keymap("<leader>b", nil, { description = "Buffers" })
  M.register_keymap("<leader>g", nil, { description = "Git" })
  M.register_keymap("<leader>l", nil, { description = "LSP" })
  
  -- Setup initial context keymaps
  vim.api.nvim_create_autocmd({"VimEnter"}, {
    callback = function()
      vim.defer_fn(function() 
        M.update_context_keymaps()
      end, 100)
    end
  })
  
  -- Listen for events from other modules
  local state = require("core.state")
  state.on("lsp.attached", function(data)
    -- When LSP attaches, update context keymaps
    M.update_context_keymaps()
  end)
end

-- Register module with core
require("core").register("keybindings", M)

return M