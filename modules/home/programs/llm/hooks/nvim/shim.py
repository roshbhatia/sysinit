#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["msgpack>=1.0"]
# ///
"""
shim - Neovim msgpack-rpc integration for LLM agents.

One-shot: connect to the nvim instance at NVIM_SOCKET_PATH, run a command,
print any result as JSON to stdout, and exit.

All Lua runs via nvim_exec_lua which is a blocking RPC call — nvim processes
the request, including any blocking vim.fn.confirm / vim.fn.input calls, and
only sends the response when the Lua returns. No polling, no temp files.

Commands:
  status
  open <file>
  preview <file>            proposed content read from stdin;
                            prints JSON: {decision, content?, reason?}
  revert <file>
  close-tab
  checktime
  set <name> <lua-value>    e.g. set pi_active true
  unset <name>
"""

import json
import os
import socket
import sys

import msgpack

SOCKET_PATH = os.environ.get("NVIM_SOCKET_PATH", "")


# ── RPC client ────────────────────────────────────────────────────────────────

class NvimRPC:
    """Minimal msgpack-rpc client for a Neovim Unix socket."""

    def __init__(self, path: str) -> None:
        self._sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self._sock.connect(path)
        self._msgid = 0
        self._buf = msgpack.Unpacker(raw=False, strict_map_key=False)

    def request(self, method: str, *params) -> object:
        msgid = self._msgid
        self._msgid += 1
        self._sock.sendall(msgpack.packb([0, msgid, method, list(params)]))
        while True:
            chunk = self._sock.recv(65536)
            if not chunk:
                raise RuntimeError("nvim socket closed unexpectedly")
            self._buf.feed(chunk)
            for msg in self._buf:
                if msg[0] == 1 and msg[1] == msgid:   # our response
                    if msg[2]:
                        raise RuntimeError(f"nvim: {msg[2]}")
                    return msg[3]
                # msg[0] == 2 is a notification; skip and keep reading

    def exec_lua(self, code: str, args: list | None = None) -> object:
        return self.request("nvim_exec_lua", code, args or [])

    def close(self) -> None:
        self._sock.close()


# ── Helpers ───────────────────────────────────────────────────────────────────

def die(msg: str) -> None:
    print(f"shim: {msg}", file=sys.stderr)
    sys.exit(1)


def connect() -> NvimRPC:
    if not SOCKET_PATH:
        die("NVIM_SOCKET_PATH is not set")
    if not os.path.exists(SOCKET_PATH):
        die(f"socket not found: {SOCKET_PATH}")
    try:
        return NvimRPC(SOCKET_PATH)
    except OSError as e:
        die(f"cannot connect to nvim: {e}")


# ── Lua ───────────────────────────────────────────────────────────────────────

LUA_OPEN = r"""
local raw_path = ...
local edit_path = vim.fn.fnameescape(raw_path)
if vim.g.agent_tab then
  local ok = pcall(vim.cmd, 'tabnext ' .. vim.g.agent_tab)
  if not ok then vim.g.agent_tab = nil end
end
if vim.g.agent_tab then
  vim.cmd('edit ' .. edit_path)
else
  vim.cmd('tabnew ' .. edit_path)
  vim.g.agent_tab = vim.fn.tabpagenr()
end
"""

LUA_REVERT = r"""
local raw_path = ...
local wins = vim.g.agent_diff_wins
if wins then
  vim.g.agent_diff_wins = nil
  for _, w in ipairs(wins) do
    if vim.api.nvim_win_is_valid(w) then
      vim.api.nvim_set_current_win(w)
      pcall(vim.cmd, 'diffoff')
    end
  end
  if vim.api.nvim_win_is_valid(wins[2]) then
    vim.api.nvim_win_close(wins[2], true)
  end
end
if vim.g.agent_tab then
  pcall(vim.cmd, 'tabnext ' .. vim.g.agent_tab)
end
vim.cmd('edit! ' .. vim.fn.fnameescape(raw_path))
"""

# Vimdiff review with fully blocking hunk-by-hunk confirm / input.
# Args passed via nvim_exec_lua varargs: raw_path (string), proposed_content (string)
# Returns a Lua table decoded by msgpack into a Python dict:
#   {decision="accept", content="...", reason="..."}   -- partial or full accept
#   {decision="reject", reason="..."}
LUA_PREVIEW = r"""
local raw_path, proposed_content = ...
local edit_path  = vim.fn.fnameescape(raw_path)
local short_path = vim.fn.fnamemodify(raw_path, ':~:.')

-- vim.ui.select (fastaction) relies on buffer-local keymaps dispatching
-- normally. Inside nvim_exec_lua, nvim is in RPC-processing mode and keymap
-- dispatch is suspended, so keypresses are swallowed. getcharstr() is a
-- C-level blocking primitive that reads raw terminal input directly and works
-- fine in this context. Build a small float that looks like fastaction.
--
-- items = { { key='a', label='Accept' }, ... }
-- Returns the selected label, or nil if cancelled.
local function ui_select(prompt, items)
  local lines = { ' ' .. prompt, '' }
  local w = #prompt + 4
  for _, item in ipairs(items) do
    local line = string.format('  %s  %s', item.key, item.label)
    table.insert(lines, line)
    w = math.max(w, #line + 2)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local row = math.floor((vim.o.lines   - #lines) / 2)
  local col = math.floor((vim.o.columns - w)      / 2)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor', row = row, col = col,
    width = w, height = #lines, border = 'rounded', style = 'minimal',
  })
  vim.wo[win].cursorline = true

  -- Highlight the title line
  local ns = vim.api.nvim_create_namespace('')
  vim.api.nvim_buf_add_highlight(buf, ns, 'Title', 0, 0, -1)

  local FIRST  = 3   -- 1-based line number of first choice
  local cursor = 1
  vim.api.nvim_win_set_cursor(win, { FIRST, 0 })

  local UP  = vim.api.nvim_replace_termcodes('<Up>',   true, false, true)
  local DN  = vim.api.nvim_replace_termcodes('<Down>', true, false, true)
  local CR  = vim.api.nvim_replace_termcodes('<CR>',   true, false, true)
  local ESC = vim.api.nvim_replace_termcodes('<Esc>',  true, false, true)

  local result, running = nil, true
  while running do
    vim.cmd('redraw')
    local ch = vim.fn.getcharstr()
    if ch == 'j' or ch == DN then
      cursor = math.min(cursor + 1, #items)
      vim.api.nvim_win_set_cursor(win, { FIRST + cursor - 1, 0 })
    elseif ch == 'k' or ch == UP then
      cursor = math.max(cursor - 1, 1)
      vim.api.nvim_win_set_cursor(win, { FIRST + cursor - 1, 0 })
    elseif ch == CR then
      result  = items[cursor].label
      running = false
    elseif ch == ESC or ch == 'q' then
      running = false
    else
      for _, item in ipairs(items) do
        if ch == item.key then
          result  = item.label
          running = false
          break
        end
      end
    end
  end

  vim.api.nvim_win_close(win, true)
  vim.api.nvim_buf_delete(buf, { force = true })
  return result
end

-- Move to next diff hunk without wrapping (wrapscan disabled temporarily so
-- pcall fails cleanly when there are no more hunks instead of looping forever).
local function next_hunk()
  local saved = vim.o.wrapscan
  vim.o.wrapscan = false
  local ok = pcall(vim.cmd, 'normal! ]c')
  vim.o.wrapscan = saved
  return ok
end

-- Open / switch to agent tab; left pane = current file on disk
if vim.g.agent_tab then
  local ok = pcall(vim.cmd, 'tabnext ' .. vim.g.agent_tab)
  if not ok then vim.g.agent_tab = nil end
end
if vim.g.agent_tab then
  vim.cmd('edit ' .. edit_path)
else
  vim.cmd('tabnew ' .. edit_path)
  vim.g.agent_tab = vim.fn.tabpagenr()
end

local left_win = vim.api.nvim_get_current_win()
local left_buf  = vim.api.nvim_win_get_buf(left_win)
local ft        = vim.bo.filetype

vim.cmd('diffthis')

-- Right pane: scratch buffer with proposed content (read-only)
local new_buf   = vim.api.nvim_create_buf(false, true)
local new_lines = vim.split(proposed_content, '\n', { plain = true })
vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, new_lines)
vim.bo[new_buf].filetype   = ft
vim.bo[new_buf].modifiable = false
vim.bo[new_buf].buftype    = 'nofile'

vim.cmd('vsplit')
vim.api.nvim_win_set_buf(0, new_buf)
vim.cmd('diffthis')
local right_win = vim.api.nvim_get_current_win()

vim.g.agent_diff_wins = { left_win, right_win }

local function cleanup()
  local wins = vim.g.agent_diff_wins
  if not wins then return end
  vim.g.agent_diff_wins = nil
  for _, w in ipairs(wins) do
    if vim.api.nvim_win_is_valid(w) then
      vim.api.nvim_set_current_win(w)
      pcall(vim.cmd, 'diffoff')
    end
  end
  if vim.api.nvim_win_is_valid(wins[2]) then
    vim.api.nvim_win_close(wins[2], true)
  end
  if vim.api.nvim_win_is_valid(left_win) then
    vim.api.nvim_set_current_win(left_win)
  end
end

-- Jump to first hunk from top of file
vim.api.nvim_set_current_win(left_win)
vim.cmd('normal! gg')

if not next_hunk() then
  -- Files are identical; accept immediately
  cleanup()
  local lines = vim.api.nvim_buf_get_lines(left_buf, 0, -1, false)
  return { decision = 'accept', content = table.concat(lines, '\n') }
end

-- Hunk-by-hunk review: getcharstr()-based float, fully blocking inside RPC
local CHOICES = {
  { key = 'a', label = 'Accept'     },
  { key = 'r', label = 'Reject'     },
  { key = 'A', label = 'Accept all' },
  { key = 'R', label = 'Reject all' },
}
local rejected_notes = {}
local done = false

while not done do
  vim.api.nvim_set_current_win(left_win)
  local choice = ui_select('pi › ' .. short_path, CHOICES)

  if choice == 'Accept' then
    pcall(vim.cmd, 'diffget')
    if not next_hunk() then done = true end

  elseif choice == 'Reject' then
    local note = vim.fn.input('Reason (optional): ')
    if note ~= '' then table.insert(rejected_notes, note) end
    if not next_hunk() then done = true end

  elseif choice == 'Accept all' then
    pcall(vim.cmd, 'diffget')
    while next_hunk() do pcall(vim.cmd, 'diffget') end
    done = true

  else  -- 'Reject all' or nil (dismissed)
    local reason = vim.fn.input('Reason: ')
    cleanup()
    return {
      decision = 'reject',
      reason   = reason ~= '' and reason or 'Rejected',
    }
  end
end

cleanup()

local lines  = vim.api.nvim_buf_get_lines(left_buf, 0, -1, false)
local result = { decision = 'accept', content = table.concat(lines, '\n') }
if #rejected_notes > 0 then
  result.reason = table.concat(rejected_notes, '; ')
end
return result
"""


# ── Commands ──────────────────────────────────────────────────────────────────

def cmd_status() -> None:
    nvim = connect()
    print(f"connected: {SOCKET_PATH}")
    nvim.close()


def cmd_open(file_path: str) -> None:
    nvim = connect()
    nvim.exec_lua(LUA_OPEN, [file_path])
    nvim.close()


def cmd_preview(file_path: str) -> None:
    proposed_content = sys.stdin.read()
    nvim = connect()
    result = nvim.exec_lua(LUA_PREVIEW, [file_path, proposed_content])
    print(json.dumps(result))
    nvim.close()


def cmd_revert(file_path: str) -> None:
    nvim = connect()
    nvim.exec_lua(LUA_REVERT, [file_path])
    nvim.close()


def cmd_close_tab() -> None:
    nvim = connect()
    nvim.exec_lua(r"""
if vim.g.agent_tab then
  pcall(vim.cmd, 'tabclose ' .. vim.g.agent_tab)
  vim.g.agent_tab = nil
end
""")
    nvim.close()


def cmd_checktime() -> None:
    nvim = connect()
    nvim.exec_lua("vim.cmd('checktime')")
    nvim.close()


def cmd_set(name: str, lua_value: str) -> None:
    # lua_value is a raw Lua expression, e.g. "true" or "false"
    nvim = connect()
    nvim.exec_lua(f"vim.g[...] = {lua_value}", [name])
    nvim.close()


def cmd_unset(name: str) -> None:
    nvim = connect()
    nvim.exec_lua("vim.g[...] = nil", [name])
    nvim.close()


# ── Dispatch ──────────────────────────────────────────────────────────────────

USAGE = """\
usage: shim <command> [args]

  status
  open <file>
  preview <file>           proposed content on stdin; prints JSON result
  revert <file>
  close-tab
  checktime
  set <name> <lua-value>
  unset <name>
"""


def main() -> None:
    args = sys.argv[1:]
    if not args:
        print(USAGE, file=sys.stderr)
        sys.exit(1)

    cmd, *rest = args
    try:
        match cmd:
            case "status":                  cmd_status()
            case "open":                    cmd_open(rest[0])
            case "preview":                 cmd_preview(rest[0])
            case "revert":                  cmd_revert(rest[0])
            case "close-tab":               cmd_close_tab()
            case "checktime":               cmd_checktime()
            case "set":                     cmd_set(rest[0], rest[1])
            case "unset":                   cmd_unset(rest[0])
            case _:                         die(f"unknown command: {cmd}")
    except (RuntimeError, OSError, IndexError) as e:
        die(str(e))


if __name__ == "__main__":
    main()
