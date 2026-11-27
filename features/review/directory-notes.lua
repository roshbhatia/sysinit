vim.api.nvim_create_user_command("WorkspaceNote", function(args)
  local buffer = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buffer)
  if file == "" or vim.bo[buffer].modified then
    vim.notify("Save the file before adding a workspace note.", vim.log.levels.ERROR)
    return
  end

  vim.ui.input({ prompt = "Workspace note: " }, function(message)
    if not message or vim.trim(message) == "" then
      return
    end
    vim.system(
      {
        vim.env.SYSINIT_REVIEW_NOTE_COMMAND,
        "note",
        vim.env.SYSINIT_REVIEW_NOTE_WORKSPACE,
        file,
        tostring(args.line2),
        message,
        "--working-file",
        "--start-line",
        tostring(args.line1),
      },
      { text = true },
      vim.schedule_wrap(function(result)
        if result.code == 0 then
          vim.notify("Saved workspace note.")
        else
          vim.notify(vim.trim(result.stderr), vim.log.levels.ERROR)
        end
      end)
    )
  end)
end, { range = true })
