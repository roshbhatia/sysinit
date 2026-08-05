-- Floating file preview for the node under the cursor (toggled with `K`).
-- Fyler has no built-in preview, so this follows the cursor while open.
local preview = { win = nil, buf = nil, group = nil }

local function close_preview()
  if preview.group then
    pcall(vim.api.nvim_del_augroup_by_id, preview.group)
    preview.group = nil
  end
  if preview.win and vim.api.nvim_win_is_valid(preview.win) then
    vim.api.nvim_win_close(preview.win, true)
  end
  preview.win, preview.buf = nil, nil
end

local function render_preview(path)
  if not (preview.buf and vim.api.nvim_buf_is_valid(preview.buf)) then
    return
  end
  local ok, lines = pcall(vim.fn.readfile, path, "", 2000)
  if not ok then
    lines = { "-- unreadable --" }
  end
  vim.bo[preview.buf].modifiable = true
  vim.api.nvim_buf_set_lines(preview.buf, 0, -1, false, lines)
  vim.bo[preview.buf].modifiable = false
  local ft = vim.filetype.match({ filename = path, buf = preview.buf })
  vim.bo[preview.buf].filetype = ft or ""
  if preview.win and vim.api.nvim_win_is_valid(preview.win) then
    vim.api.nvim_win_set_config(preview.win, { title = " " .. vim.fs.basename(path) .. " " })
  end
end

local function node_path(finder)
  local node = require("fyler.finder").parse_cursor_line(finder)
  if not node or node.type == "directory" then
    return nil
  end
  return node.link_target or node.full_path
end

local function toggle_preview(finder)
  if preview.win and vim.api.nvim_win_is_valid(preview.win) then
    close_preview()
    return
  end
  local path = node_path(finder)
  if not path then
    return
  end

  preview.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[preview.buf].buftype = "nofile"
  vim.bo[preview.buf].bufhidden = "wipe"

  local width = math.floor(vim.o.columns * 0.5)
  local height = math.floor(vim.o.lines * 0.6)
  preview.win = vim.api.nvim_open_win(preview.buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = vim.o.columns - width - 2,
    border = "rounded",
    style = "minimal",
    focusable = false,
    title = "",
  })
  render_preview(path)

  -- Follow the cursor and tear down when leaving the explorer.
  preview.group = vim.api.nvim_create_augroup("FylerPreview", { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = preview.group,
    buffer = finder.buf_id,
    callback = function()
      local p = node_path(finder)
      if p then
        render_preview(p)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed" }, {
    group = preview.group,
    buffer = finder.buf_id,
    callback = close_preview,
  })
end

return {
  {
    "FylerOrg/fyler.nvim",
    cmd = "Fyler",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      {
        "<leader>et",
        function()
          require("fyler").toggle({ kind = "split_left_most" })
        end,
        desc = "Toggle explorer tree",
      },
    },
    opts = {
      -- oil owns netrw (default_file_explorer = true); keep fyler out of that role
      use_as_default_explorer = false,
      follow_current_file = true,
      kind = "split_left_most",
      kind_presets = {
        split_left_most = { width = "23%" },
      },
      integrations = {
        icon = "nvim_web_devicons",
      },
      extensions = {
        git = {},
      },
      mappings = {
        n = {
          -- open (localleader mirrors oil: s/v/t splits, p preview)
          ["<CR>"] = { action = "select" },
          ["<localleader>s"] = { action = "select", args = { split = true } },
          ["<localleader>v"] = { action = "select", args = { vsplit = true } },
          ["<localleader>t"] = { action = "select", args = { tabedit = true } },
          ["K"] = { action = toggle_preview },
          ["<localleader>p"] = { action = toggle_preview },
          -- tree / root navigation
          ["<localleader>u"] = { action = "visit", args = { parent = true } },
          ["<localleader>."] = { action = "visit", args = { cursor = true } },
          ["<localleader>="] = { action = "visit" },
          ["<localleader>c"] = { action = "shrink", args = { parent = true } },
          -- view toggles
          ["<localleader>h"] = { action = "toggle_ui", args = { "hidden_items" } },
          ["<localleader>g"] = { action = "toggle_ui", args = { "indent_guides" } },
          -- refresh / close
          ["<localleader>r"] = { action = "refresh" },
          ["q"] = { action = "close" },
          -- disable defaults superseded by the localleader scheme
          ["<C-s>"] = { action = false },
          ["<C-v>"] = { action = false },
          ["<C-t>"] = { action = false },
          ["<C-r>"] = { action = false },
          ["-"] = { action = false },
          ["."] = { action = false },
          ["="] = { action = false },
          ["<BS>"] = { action = false },
          ["g."] = { action = false },
          ["gi"] = { action = false },
        },
      },
      hooks = {
        on_rename = function(old_path, new_path)
          Snacks.rename.on_rename_file(old_path, new_path)
        end,
      },
    },
  },
}
