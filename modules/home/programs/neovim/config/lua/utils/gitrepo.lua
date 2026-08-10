local M = {}

local SCAN_DEPTH = 5

local function toplevel(dir)
  if not dir or dir == "" then
    return nil
  end
  local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return nil
  end
  return vim.fs.normalize(out[1])
end

function M.buffer_root(buf)
  local file = vim.api.nvim_buf_get_name(buf or 0)
  if file == "" or not vim.uv.fs_stat(file) then
    return nil
  end
  return toplevel(vim.fn.fnamemodify(file, ":h"))
end

function M.cwd_root()
  return toplevel(vim.uv.cwd())
end

function M.scan(dir, cb)
  vim.system(
    { "fd", "-H", "-I", "-t", "d", "-t", "f", "--max-depth", tostring(SCAN_DEPTH), "^[.]git$", dir },
    { text = true },
    function(res)
      local roots, seen = {}, {}
      for line in (res.stdout or ""):gmatch("[^\n]+") do
        local root = line:match("^(.+)/%.git/?$")
        if root and not seen[root] then
          seen[root] = true
          roots[#roots + 1] = vim.fs.normalize(root)
        end
      end
      table.sort(roots)
      vim.schedule(function()
        cb(roots)
      end)
    end
  )
end

-- Resolve one repo root for a command that needs one, preferring the repo the
-- current buffer lives in so a workspace holding several repos does not prompt.
function M.resolve(cb)
  local root = M.buffer_root() or M.cwd_root()
  if root then
    return cb(root)
  end

  M.scan(vim.uv.cwd(), function(roots)
    if #roots == 0 then
      vim.notify("No git repository under " .. vim.fn.fnamemodify(vim.uv.cwd(), ":~"), vim.log.levels.WARN)
      return
    end
    if #roots == 1 then
      return cb(roots[1])
    end
    vim.ui.select(roots, {
      prompt = "Select git repo",
      format_item = function(r)
        return vim.fn.fnamemodify(r, ":~:.")
      end,
    }, function(choice)
      if choice then
        cb(choice)
      end
    end)
  end)
end

return M
