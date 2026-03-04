#!/usr/bin/env bash
# nvim-shim - Neovim integration shim for LLM agents.
#
# All Lua logic for interacting with Neovim lives here. Agent extensions
# (pi, claude, etc.) call this script with high-level commands rather than
# building Lua themselves.
#
# Uses NVIM_SOCKET_PATH, exported by Neovim on startup via:
#   vim.env.NVIM_SOCKET_PATH = vim.fn.stdpath("run") .. "/nvim-" .. vim.fn.getpid() .. ".sock"
# Inherited automatically by terminal panes spawned from within Neovim.
#
# Commands:
#   nvim-shim status                              Check socket and print connection info
#   nvim-shim open <file>                         Open file in the agent tab
#   nvim-shim preview <file> <content> <result>   Vimdiff proposed changes; hunk-by-hunk
#                                                 accept/reject in Neovim. Blocks until done.
#                                                 Writes JSON to <result>: {decision, content_path?, reason?}
#   nvim-shim revert <file>                       Reload file from disk (reject cleanup)
#   nvim-shim close-tab                           Close the agent tab
#   nvim-shim checktime                           Reload all buffers from disk
#   nvim-shim set <name> <value>                  Set a vim.g global (raw Lua value)
#   nvim-shim unset <name>                        Clear a vim.g global
#   nvim-shim lua <expr>                          Evaluate a raw Lua expression

set -euo pipefail

SOCKET="${NVIM_SOCKET_PATH:-}"
TMPDIR="${TMPDIR:-/tmp}"

die() { echo "nvim-shim: $*" >&2; exit 1; }

check_socket() {
  [[ -n "$SOCKET" ]] || die "NVIM_SOCKET_PATH is not set"
  [[ -S "$SOCKET" ]] || die "socket not found: $SOCKET"
}

# Wrap nvim --server with a hard timeout so a blocked/stale nvim instance
# never hangs the calling process.
send_keys() {
  timeout 2 nvim --server "$SOCKET" --remote-send "$1" 2>/dev/null || true
}

# Write Lua to a temp file and execute via :luafile.
# Cleanup runs in background after a short delay.
run_lua() {
  local tmp
  tmp=$(mktemp "${TMPDIR}/nvim-shim-XXXXXX.lua")
  printf '%s\n' "$1" > "$tmp"
  send_keys ":luafile ${tmp}<CR>"
  { sleep 0.3 && rm -f "$tmp"; } &
}

# Escape a string for embedding inside a Lua double-quoted string literal.
lua_str() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

# ---

case "${1:-}" in
  status)
    if [[ -z "$SOCKET" ]]; then
      echo "no socket (NVIM_SOCKET_PATH not set)"
      exit 1
    elif [[ ! -S "$SOCKET" ]]; then
      echo "socket not found: $SOCKET"
      exit 1
    else
      echo "connected: $SOCKET"
    fi
    ;;

  open)
    check_socket
    shift
    [[ -n "${1:-}" ]] || die "open requires a file path"
    path="$(lua_str "$1")"
    run_lua "
local path = vim.fn.fnameescape(\"${path}\")
if vim.g.agent_tab then
  local ok = pcall(vim.cmd, 'tabnext ' .. vim.g.agent_tab)
  if not ok then vim.g.agent_tab = nil end
end
if vim.g.agent_tab then
  vim.cmd('edit ' .. path)
else
  vim.cmd('tabnew ' .. path)
  vim.g.agent_tab = vim.fn.tabpagenr()
end
"
    ;;

  preview)
    # Vimdiff the proposed changes hunk-by-hunk inside Neovim.
    #
    # Left pane  = current file on disk (writable — diffget applies hunks here)
    # Right pane = scratch buffer with the full proposed content (read-only)
    #
    # vim.ui.select drives per-hunk review:
    #   Accept      — apply this hunk (diffget), advance to next
    #   Reject      — skip this hunk, prompt for optional reason, advance
    #   Accept all  — apply this + all remaining hunks
    #   Reject all  — prompt for reason, discard everything
    #
    # Result JSON written to <result-file>:
    #   accept: {"decision":"accept","content_path":"/tmp/..."}
    #   reject: {"decision":"reject","reason":"..."}
    #
    # Shell exits 0 on user decision, 1 on timeout (120 s).
    check_socket
    [[ -n "${2:-}" ]] || die "preview requires <file> <proposed-content> <result-json>"
    [[ -n "${3:-}" ]] || die "preview requires <file> <proposed-content> <result-json>"
    [[ -n "${4:-}" ]] || die "preview requires <file> <proposed-content> <result-json>"

    file_path="$(lua_str "$2")"
    proposed_file="$(lua_str "$3")"
    result_json_path="${4}"
    result_path="$(lua_str "$result_json_path")"

    content_out=$(mktemp "${TMPDIR}/nvim-content-XXXXXX")
    rm -f "$content_out"
    content_path="$(lua_str "$content_out")"

    run_lua "
local raw_path      = \"${file_path}\"
local edit_path     = vim.fn.fnameescape(raw_path)
local proposed_file = \"${proposed_file}\"
local result_file   = \"${result_path}\"
local content_out   = \"${content_path}\"

-- Open / switch to agent tab; left pane shows the current file
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

-- Right pane: scratch buffer with proposed content (read-only, not a real file)
local new_buf   = vim.api.nvim_create_buf(false, true)
local new_lines = vim.fn.readfile(proposed_file)
vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, new_lines)
vim.bo[new_buf].filetype    = ft
vim.bo[new_buf].modifiable  = false
vim.bo[new_buf].buftype     = 'nofile'

vim.cmd('vsplit')
vim.api.nvim_win_set_buf(0, new_buf)
local right_win = vim.api.nvim_get_current_win()
vim.cmd('diffthis')

vim.g.agent_diff_wins = { left_win, right_win }

local short_path     = vim.fn.fnamemodify(raw_path, ':~:.')
local rejected_notes = {}

local function cleanup_diff()
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

local function write_result(decision, reason)
  -- Capture left buffer state (accepted hunks applied, rejected hunks unchanged)
  local lines = vim.api.nvim_buf_get_lines(left_buf, 0, -1, false)
  local cf = io.open(content_out, 'w')
  if cf then cf:write(table.concat(lines, '\n')); cf:close() end

  local result = { decision = decision, content_path = content_out }
  if reason and reason ~= '' then result.reason = reason end

  cleanup_diff()

  local rf = io.open(result_file, 'w')
  if rf then rf:write(vim.fn.json_encode(result)); rf:close() end
end

-- Forward declaration for mutual recursion
local process_next_hunk

local function show_hunk_prompt()
  vim.ui.select(
    { 'Accept', 'Reject', 'Accept all', 'Reject all' },
    { prompt = 'pi: ' .. short_path },
    function(choice)
      if choice == 'Accept' then
        vim.api.nvim_set_current_win(left_win)
        pcall(vim.cmd, 'diffget')
        process_next_hunk()

      elseif choice == 'Reject' then
        vim.ui.input({ prompt = 'Reason (optional): ' }, function(input)
          if input and input ~= '' then
            table.insert(rejected_notes, input)
          end
          process_next_hunk()
        end)

      elseif choice == 'Accept all' then
        vim.api.nvim_set_current_win(left_win)
        pcall(vim.cmd, 'diffget')
        while pcall(function()
          vim.cmd('normal! ]c')
          vim.cmd('diffget')
        end) do end
        local notes = #rejected_notes > 0 and table.concat(rejected_notes, '; ') or nil
        write_result('accept', notes)

      else  -- 'Reject all' or nil (dismissed)
        vim.ui.input({ prompt = 'Reason: ' }, function(input)
          local reason = (input and input ~= '') and input or 'Rejected'
          write_result('reject', reason)
        end)
      end
    end
  )
end

process_next_hunk = function()
  vim.api.nvim_set_current_win(left_win)
  local ok = pcall(vim.cmd, 'normal! ]c')
  if not ok then
    -- No more hunks — accept with any accumulated rejection notes
    local notes = #rejected_notes > 0 and table.concat(rejected_notes, '; ') or nil
    write_result('accept', notes)
    return
  end
  show_hunk_prompt()
end

-- Jump to first hunk from top of file
vim.api.nvim_set_current_win(left_win)
vim.cmd('normal! gg')
if pcall(vim.cmd, 'normal! ]c') then
  show_hunk_prompt()
else
  write_result('accept', nil)  -- files already identical
end
"

    # Poll for result JSON (up to 120 s)
    local count=0
    while [[ ! -f "$result_json_path" ]] && [[ $count -lt 1200 ]]; do
      sleep 0.1
      count=$((count + 1))
    done

    if [[ ! -f "$result_json_path" ]]; then
      rm -f "$content_out"
      exit 1  # timeout — treat as reject
    fi
    ;;

  revert)
    # Reload file from disk. Also cleans up any leftover diff split.
    check_socket
    [[ -n "${2:-}" ]] || die "revert requires a file path"
    file_path="$(lua_str "$2")"
    run_lua "
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
vim.cmd('edit! ' .. vim.fn.fnameescape(\"${file_path}\"))
"
    ;;

  close-tab)
    check_socket
    run_lua "
if vim.g.agent_tab then
  pcall(vim.cmd, 'tabclose ' .. vim.g.agent_tab)
  vim.g.agent_tab = nil
end
"
    ;;

  checktime)
    check_socket
    send_keys ":checktime<CR>"
    ;;

  set)
    check_socket
    [[ -n "${2:-}" ]] || die "set requires <name> <value>"
    [[ -n "${3:-}" ]] || die "set requires <name> <value>"
    send_keys ":lua vim.g.${2} = ${3}<CR>"
    ;;

  unset)
    check_socket
    [[ -n "${2:-}" ]] || die "unset requires <name>"
    send_keys ":lua vim.g.${2} = nil<CR>"
    ;;

  lua)
    check_socket
    shift
    [[ -n "${1:-}" ]] || die "lua requires an expression"
    send_keys ":lua ${1}<CR>"
    ;;

  "")
    die "usage: nvim-shim <status|open|preview|revert|close-tab|checktime|set|unset|lua> [args...]"
    ;;

  *)
    die "unknown command: ${1}"
    ;;
esac
