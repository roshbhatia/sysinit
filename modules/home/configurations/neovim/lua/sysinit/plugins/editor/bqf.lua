local fn = vim.fn

local function get_relative_path(filepath)
  local cwd = vim.fn.getcwd()
  if filepath:find(cwd, 1, true) == 1 then
    return filepath:sub(#cwd + 2)
  end
  return filepath:gsub("^" .. vim.env.HOME, "~")
end

local function truncate_path(path, max_len)
  if #path <= max_len then
    return path
  end

  local parts = vim.split(path, "/")
  if #parts <= 2 then
    return "…" .. path:sub(-(max_len - 1))
  end

  local filename = parts[#parts]
  local available = max_len - #filename - 2
  if available < 3 then
    return "…" .. path:sub(-(max_len - 1))
  end

  local parent = parts[#parts - 1]
  if #parent > available then
    parent = parent:sub(1, available - 1) .. "…"
  end

  return parent .. "/" .. filename
end

local function format_qf_item(item, fname_width)
  if item.valid ~= 1 then
    return item.text
  end

  local fname = ""
  if item.bufnr > 0 then
    local bufname = fn.bufname(item.bufnr)
    if bufname == "" then
      fname = "[No Name]"
    else
      fname = truncate_path(get_relative_path(bufname), fname_width)
    end
  end

  local lnum = item.lnum > 99999 and "~" or tostring(item.lnum)
  local col = item.col > 999 and "~" or tostring(item.col)
  local qtype = item.type == "" and " " or item.type:sub(1, 1):upper()

  local type_icon = {
    E = "",
    W = "",
    I = "",
    H = "",
  }

  local icon = type_icon[qtype] or " "
  local text = item.text:gsub("^%s+", "")

  return string.format(
    "%-" .. fname_width .. "s │ %5s:%-3s │ %s %s",
    fname,
    lnum,
    col,
    icon,
    text
  )
end

function _G.qftf(info)
  local items
  if info.quickfix == 1 then
    items = fn.getqflist({ id = info.id, items = 0 }).items
  else
    items = fn.getloclist(info.winid, { id = info.id, items = 0 }).items
  end

  local ret = {}
  local fname_width = 35

  for i = info.start_idx, info.end_idx do
    table.insert(ret, format_qf_item(items[i], fname_width))
  end

  return ret
end

vim.o.qftf = "{info -> v:lua._G.qftf(info)}"

local function refresh_qf_on_save()
  local qf_list = vim.fn.getqflist({ title = 1, items = 1 })
  if #qf_list.items == 0 then
    return
  end

  local new_items = {}
  for _, item in ipairs(qf_list.items) do
    if item.bufnr > 0 and vim.fn.bufexists(item.bufnr) == 1 then
      local bufname = vim.fn.bufname(item.bufnr)
      if bufname ~= "" and vim.fn.filereadable(bufname) == 1 then
        local lines = vim.fn.readfile(bufname)
        if item.lnum > 0 and item.lnum <= #lines then
          item.text = lines[item.lnum]
          table.insert(new_items, item)
        end
      end
    end
  end

  if #new_items > 0 then
    vim.fn.setqflist({}, "r", { items = new_items, title = qf_list.title })
  end
end

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("QuickfixAutoRefresh", { clear = true }),
  callback = refresh_qf_on_save,
  desc = "Auto-refresh quickfix list on buffer save",
})

local M = {}

M.plugins = {
  {
    "kevinhwang91/nvim-bqf",
    event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("bqf").setup({
        func_map = {
          split = "<localleader>s",
          tabb = "",
          tabc = "",
          vsplit = "<localleader>v",
        },
        preview = {
          winblend = 0,
        },
        show_title = {
          description = [[Show the window title]],
          default = false,
        },
        filter = {
          fzf = {
            extra_opts = { "--bind", "ctrl-o:toggle-all", "--delimiter", "│" },
          },
        },
      })
    end,
  },
}

return M
