-- What a review holds: one section per state a change can be in, and one entry per file,
-- carrying both sides of its diff.
local M = {}

-- git's empty tree, which is the only left side a root commit has.
local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

--- Run one git command in root. `core.quotePath=false` so a path holding a non-ASCII
--- character arrives as itself rather than as escapes.
---@param root string
---@param args string[]
---@param cb fun(out: string|nil, why: string|nil)
local function git(root, args, cb)
  local full = { "git", "-C", root, "-c", "core.quotePath=false" }
  vim.list_extend(full, args)
  vim.system(full, { text = true }, function(res)
    if res.code == 0 then
      return cb(res.stdout, nil)
    end
    cb(nil, vim.split(res.stderr or "", "\n")[1])
  end)
end

--- Split a NUL-separated answer into its fields. A plain `find` rather than a pattern,
--- because LuaJIT cuts a pattern at its first NUL and `([^\0]*)\0` arrives malformed.
---@param text string|nil
---@return string[]
local function fields(text)
  local out, at = {}, 1
  text = text or ""
  while true do
    local stop = text:find("\0", at, true)
    if stop == nil then
      return out
    end
    out[#out + 1] = text:sub(at, stop - 1)
    at = stop + 1
  end
end

--- `--name-status -z` gives `status`, `path`, and a rename gives `status`, `from`, `path`.
---@param text string|nil
---@return table[]
local function parse_status(text)
  local found, all, at = {}, fields(text), 1
  while at <= #all do
    local status = all[at]
    if status == "" then
      break
    end
    if status:match("^[RC]") then
      found[#found + 1] = { status = status, from = all[at + 1], path = all[at + 2] }
      at = at + 3
    else
      found[#found + 1] = { status = status, path = all[at + 1] }
      at = at + 2
    end
  end
  return found
end

--- `--numstat -z` gives one `added\tremoved\tpath` field, except for a rename, whose
--- field ends at the second tab and whose two paths follow as fields of their own.
---@param text string|nil
---@return table<string, table>
local function parse_counts(text)
  local counts, all, at = {}, fields(text), 1
  while at <= #all do
    local added, removed, path = all[at]:match("^([^\t]*)\t([^\t]*)\t(.*)$")
    if added == nil then
      break
    end
    -- A binary file reports "-" for both, which is not a count.
    local record = { added = tonumber(added), removed = tonumber(removed) }
    if path == "" then
      counts[all[at + 2]] = record
      at = at + 3
    else
      counts[path] = record
      at = at + 1
    end
  end
  return counts
end

--- One diff's entries, merged from the two answers git will not give in one call.
---@param root string
---@param range string[] the arguments naming the diff, such as `{"--cached"}`
---@param sides fun(relative: string): string|nil, string|nil the left and right specs
---@param cb fun(entries: table[], why: string|nil)
local function changed(root, range, sides, cb)
  local status_args = vim.list_extend({ "diff", "-z", "--name-status" }, range)
  local count_args = vim.list_extend({ "diff", "-z", "--numstat" }, range)

  local answers, pending, failed = {}, 2, nil
  local function collect(key)
    return function(out, why)
      answers[key] = out or ""
      -- A section git refused to read is not a section with no changes, and reporting the
      -- two the same way is how a bad base reads as a clean tree.
      failed = failed or why
      pending = pending - 1
      if pending > 0 then
        return
      end
      local counts = parse_counts(answers.counts)
      local entries = {}
      for _, record in ipairs(parse_status(answers.status)) do
        local count = counts[record.path] or {}
        local left, right = sides(record.path)
        entries[#entries + 1] = {
          root = root,
          relative = record.path,
          path = root .. "/" .. record.path,
          from = record.from,
          status = record.status,
          added = count.added,
          removed = count.removed,
          left = left,
          right = right,
        }
      end
      vim.schedule(function()
        cb(entries, failed)
      end)
    end
  end

  git(root, status_args, collect("status"))
  git(root, count_args, collect("counts"))
end

--- The notes section: one entry per file carrying a note, so the list reaches a note
--- whose file no other section changed.
---@param roots string[]
---@return table[]
local function note_entries(roots)
  local notes = require("harness.notes")
  local entries = {}
  for _, root in ipairs(roots) do
    for relative, count in pairs(notes.files_in(root)) do
      entries[#entries + 1] = {
        root = root,
        relative = relative,
        path = root .. "/" .. relative,
        status = "N",
        notes = count,
        -- The working file against the index, which is what a note is written on.
        left = ":0:" .. relative,
        right = nil,
      }
    end
  end
  table.sort(entries, function(a, b)
    return a.path < b.path
  end)
  return entries
end

--- The sections of a working-tree review. `base` adds the cumulative commits since it.
---@param root string
---@param base string|nil
---@param cb fun(sections: table[])
function M.working(root, base, cb)
  local wanted = {
    {
      key = "unstaged",
      label = "changes",
      range = {},
      -- The index against the working file, so the right side is the real buffer and
      -- stays editable while it is read.
      sides = function(relative)
        return ":0:" .. relative, nil
      end,
    },
    {
      key = "staged",
      label = "staged changes",
      range = { "--cached" },
      sides = function(relative)
        return "HEAD:" .. relative, ":0:" .. relative
      end,
    },
  }
  if base then
    wanted[#wanted + 1] = {
      key = "commited",
      label = "commited changes",
      range = { base .. "..HEAD" },
      sides = function(relative)
        return base .. ":" .. relative, "HEAD:" .. relative
      end,
    }
  end

  local sections, pending = {}, #wanted
  for index, want in ipairs(wanted) do
    changed(root, want.range, want.sides, function(entries, why)
      sections[index] = { key = want.key, label = want.label, entries = entries, failed = why }
      pending = pending - 1
      if pending == 0 then
        sections[#wanted + 1] = { key = "notes", label = "notes", entries = note_entries({ root }) }
        cb(sections)
      end
    end)
  end
end

--- The one section of a revision review: what that commit changed.
---@param root string
---@param sha string
---@param parent string|nil defaults to git's empty tree, for a root commit
---@param cb fun(sections: table[])
function M.revision(root, sha, parent, cb)
  local left = parent or EMPTY_TREE
  changed(root, { left, sha }, function(relative)
    return left .. ":" .. relative, sha .. ":" .. relative
  end, function(entries, why)
    cb({
      { key = "commited", label = "commited changes", entries = entries, failed = why },
      { key = "notes", label = "notes", entries = note_entries({ root }) },
    })
  end)
end

return M
