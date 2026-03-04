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

-- next_hunk: cursor-position comparison because :normal! ]c never throws —
-- pcall would always return true and the loop would spin forever.
local function next_hunk()
  local saved  = vim.o.wrapscan
  vim.o.wrapscan = false
  local before = vim.api.nvim_win_get_cursor(0)
  pcall(vim.cmd, 'normal! ]c')
  local after  = vim.api.nvim_win_get_cursor(0)
  vim.o.wrapscan = saved
  return before[1] ~= after[1] or before[2] ~= after[2]
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
local left_buf = vim.api.nvim_win_get_buf(left_win)
local ft       = vim.bo.filetype

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

-- Defined after left_buf/left_win so the closures capture them correctly.

local review_ns = vim.api.nvim_create_namespace('pi_review')
local hunk_num  = 0

-- Inline extmark at the first line of the current hunk so the user can
-- always see which hunk is under review even while the cmdline prompt shows.
local function mark_hunk()
  hunk_num = hunk_num + 1
  vim.api.nvim_buf_clear_namespace(left_buf, review_ns, 0, -1)
  local row = vim.api.nvim_win_get_cursor(left_win)[1] - 1  -- 0-indexed
  vim.api.nvim_buf_set_extmark(left_buf, review_ns, row, 0, {
    virt_text     = { { '▸ ', 'DiagnosticInfo' } },
    virt_text_pos = 'inline',
  })
end

local function cleanup()
  vim.api.nvim_buf_clear_namespace(left_buf, review_ns, 0, -1)
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

-- Idiomatic single-keypress prompt in the cmdline — same pattern as f/t/r/etc.
local function choose()
  vim.api.nvim_echo({
    { 'hunk ' .. hunk_num .. '  ', 'Title'   },
    { 'y',                         'Keyword' }, { ' accept  ', 'Comment' },
    { 'n',                         'Keyword' }, { ' reject  ', 'Comment' },
    { 'a',                         'Keyword' }, { ' all     ', 'Comment' },
    { 'd',                         'Keyword' }, { ' done    ', 'Comment' },
    { 'e',                         'Keyword' }, { ' manual',   'Comment' },
  }, false, {})
  vim.cmd('redraw')
  local ch = vim.fn.getcharstr()
  vim.api.nvim_echo({}, false, {})
  return ch
end

local ESC = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)

-- Jump to first hunk from top of file
vim.api.nvim_set_current_win(left_win)
vim.cmd('normal! gg')

if not next_hunk() then
  cleanup()
  local lines = vim.api.nvim_buf_get_lines(left_buf, 0, -1, false)
  return { decision = 'accept', content = table.concat(lines, '\n') }
end
mark_hunk()

local rejected_notes = {}
local accepted_any   = false
local done           = false

while not done do
  vim.api.nvim_set_current_win(left_win)
  local ch = choose()

  if ch == 'y' then                           -- accept hunk
    pcall(vim.cmd, 'diffget')
    vim.cmd('diffupdate')
    accepted_any = true
    if next_hunk() then mark_hunk() else done = true end

  elseif ch == 'n' then                       -- reject hunk
    local note = vim.fn.input('Reason (optional): ')
    if note ~= '' then table.insert(rejected_notes, note) end
    if next_hunk() then mark_hunk() else done = true end

  elseif ch == 'a' then                       -- accept all remaining
    pcall(vim.cmd, 'diffget')
    vim.cmd('diffupdate')
    accepted_any = true
    while next_hunk() do
      pcall(vim.cmd, 'diffget')
      vim.cmd('diffupdate')
    end
    done = true

  elseif ch == 'd' or ch == ESC then          -- done / reject all remaining
    local reason = vim.fn.input('Reason: ')
    cleanup()
    return {
      decision = 'reject',
      reason   = reason ~= '' and reason or 'Rejected',
    }

  elseif ch == 'e' then                       -- hand off for manual edit
    cleanup()
    return { decision = 'reject', reason = 'Manual resolution' }

  end
  -- unrecognised keys are ignored and the prompt re-shows
end

cleanup()

if not accepted_any then
  return {
    decision = 'reject',
    reason   = #rejected_notes > 0
               and table.concat(rejected_notes, '; ')
               or  'All hunks rejected',
  }
end

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
