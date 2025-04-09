-- Startify configuration
local M = {}

M.setup = function()
  -- Force compatibility with neovim shada file
  vim.api.nvim_exec([[
    function! s:gitModified()
      let files = systemlist('git ls-files -m 2>/dev/null')
      return map(files, "{'line': v:val, 'path': v:val}")
    endfunction

    function! s:gitUntracked()
      let files = systemlist('git ls-files -o --exclude-standard 2>/dev/null')
      return map(files, "{'line': v:val, 'path': v:val}")
    endfunction

    function! s:listRepos()
      let output = []
      let repos = systemlist('find ~/github/personal/*/. -maxdepth 1 -type d 2>/dev/null')
      for repo in repos
        let reponame = fnamemodify(repo, ':h:t') . '/' . fnamemodify(repo, ':t')
        call add(output, {'line': '  ' . reponame, 'path': repo})
      endfor
      return output
    endfunction
  ]], false)

  -- Set correct file format for Startify
  vim.g.startify_custom_header = {
    "⠀⠀⠀⠀⠀⠀⠐⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠈⣾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⢸⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⣈⣼⣄⣠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
  }

  -- Startify options
  vim.g.startify_session_dir = vim.fn.stdpath('data') .. '/sessions'
  vim.g.startify_session_autoload = 1
  vim.g.startify_session_persistence = 1
  vim.g.startify_session_delete_buffers = 1
  vim.g.startify_change_to_dir = 1
  vim.g.startify_change_to_vcs_root = 1
  vim.g.startify_fortune_use_unicode = 1
  vim.g.startify_skiplist = { 'COMMIT_EDITMSG' }
  vim.g.startify_bookmarks = {
    { c = '~/.config/nvim/init.lua' },
    { z = '~/.zshrc' },
  }

  -- Fix for viminfo file issue
  vim.g.startify_enable_special = 0
  vim.g.startify_relative_path = 1
  vim.g.startify_files_number = 8
  vim.g.startify_update_oldfiles = 1

  -- Fix for repository display
  vim.g.startify_lists = {
    { type = 'dir',       header = {'   Current Directory:'} },
    { type = 'files',     header = {'   Recent Files:'} },
    { type = 'sessions',  header = {'   Sessions:'} },
    { type = 'bookmarks', header = {'   Bookmarks:'} },
    { type = 'commands',  header = {'   Commands:'} },
  }
  
  -- Disable broken git functions for now
  vim.g.startify_custom_indices = {'a', 'b', 'c', 'd', 'f', 'g'}
  vim.g.startify_custom_header_quotes = {{'Code. Build. Ship.'}}

  -- Force Startify to not use viminfo/shada
  vim.g.startify_enable_special = 0
  vim.g.startify_disable_at_vimenter = 0
  vim.g.startify_update_oldfiles = 1
end

return M
