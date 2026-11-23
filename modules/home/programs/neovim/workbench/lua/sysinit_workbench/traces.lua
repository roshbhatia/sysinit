local view = require("sysinit_workbench.view")
local M = {}

local function records(output, consume)
  for line in output:gmatch("[^\r\n]+") do
    local ok, record = pcall(vim.json.decode, line)
    if not ok or type(record) ~= "table" then
      return false
    end
    if consume(record) == false then
      return false
    end
  end
  return true
end

function M.open(query)
  local cwd = vim.fn.getcwd()
  local args = vim.deepcopy(query.args)
  local session
  for i, arg in ipairs(args) do
    if arg == "--session" or arg == "-session" then
      session = args[i + 1]
      break
    end
    session = arg:match("^%-%-?session=(.+)$")
    if session then
      break
    end
  end

  local function transcript(target)
    local buffer = view.buffer("traces://transcript/" .. target, "markdown")
    local argv = vim.list_extend({ query.program }, args)
    if not session then
      vim.list_extend(argv, { "--session", target })
    end
    vim.list_extend(argv, { "--view", "output", "--format", "jsonl", "--once", "--color", "never" })
    local generation = 0
    local function refresh()
      generation = generation + 1
      local request = generation
      view.query(argv, cwd, function(err, output)
        if request ~= generation or not vim.api.nvim_buf_is_valid(buffer) then
          return
        end
        local lines = { "# Traces · assistant replies", "", target, "", "r refresh  q close", "" }
        local valid = records(output or "", function(record)
          if
            record.version ~= "traces.message/v1"
            or type(record.timestamp) ~= "string"
            or type(record.body) ~= "string"
          then
            return false
          end
          if record.session == target then
            table.insert(
              lines,
              "## " .. record.timestamp .. (record.truncated and " (truncated)" or "")
            )
            table.insert(lines, "")
            vim.list_extend(lines, vim.split(record.body, "\n", { plain = true }))
            table.insert(lines, "")
          end
        end)
        if err or not valid then
          vim.notify(err or "Traces returned invalid JSON Lines", vim.log.levels.ERROR)
          if vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1] == "Loading Traces…" then
            view.render(buffer, { err or "Traces returned invalid JSON Lines" })
          end
          return
        end
        if #lines == 6 then
          table.insert(lines, "No assistant replies for this exact session.")
        end
        view.render(buffer, lines)
      end)
    end
    vim.keymap.set("n", "r", refresh, { buffer = buffer })
    vim.keymap.set("n", "q", "<cmd>tabclose<CR>", { buffer = buffer })
    view.render(buffer, { "Loading Traces…" })
    refresh()
  end

  if session then
    return transcript(session)
  end
  local argv = vim.list_extend({ query.program }, args)
  table.insert(argv, "--json")
  view.query(argv, cwd, function(err, output)
    if err then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
    local by_id = {}
    if
      not records(output, function(row)
        if type(row.session) == "string" and row.session ~= "" then
          local existing = by_id[row.session]
          if not existing or (row.startUnixNano or "") > (existing.startUnixNano or "") then
            by_id[row.session] = row
          end
        end
      end)
    then
      vim.notify("Traces returned invalid activity JSON Lines", vim.log.levels.ERROR)
      return
    end
    local sessions = vim.tbl_values(by_id)
    table.sort(sessions, function(left, right)
      return (left.startUnixNano or "") > (right.startUnixNano or "")
    end)
    if #sessions == 0 then
      vim.notify("No Traces sessions in this scope")
      return
    end
    vim.ui.select(sessions, {
      prompt = "Traces session",
      format_item = function(row)
        return ("%s  %s"):format(row.service or "agent", row.session)
      end,
    }, function(item)
      if item then
        transcript(item.session)
      end
    end)
  end)
end

return M
