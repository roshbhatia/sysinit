vim.api.nvim_create_user_command("Wpatch", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local fn = vim.api.nvim_buf_get_name(0)
  vim.system({ "git", "diff", "--no-index", fn, "-" }, { text = true, stdin = lines }, function(out)
    local f = assert(io.open(fn .. ".patch", "w"))
    f:write(out.stdout)
    f:close()
    vim.print(("patch written to %s.patch"):format(fn))
  end)
end, {
  desc = "Save changes for buffer to a patch file",
})
