local M = {}

local last_prompts = {}

-- Wait for pane to be available before sending (polling instead of defer)
function M.ensure_terminal_and_send(termname, text)
  last_prompts[termname] = text

  local ai_manager = require("sysinit.plugins.intellicode.ai.ai_manager")
  local term_info = ai_manager.get_info(termname)

  if not term_info or not term_info.visible then
    ai_manager.open(termname)
    ai_manager.focus(termname)

    -- Poll for pane to be ready (instead of arbitrary defer delay)
    local max_retries = 10
    local retry = 0
    while retry < max_retries do
      vim.fn.system("sleep 0.05")
      if ai_manager.is_visible(termname) then
        ai_manager.send(termname, text, { submit = true })
        return
      end
      retry = retry + 1
    end

    -- If we get here, pane never became visible
    vim.notify("Pane failed to become ready for sending text", vim.log.levels.ERROR)
  else
    ai_manager.focus(termname)
    -- Already visible, send immediately
    ai_manager.send(termname, text, { submit = true })
  end
end

function M.get_last_prompt(termname)
  return last_prompts[termname]
end

function M.set_last_prompt(termname, prompt)
  last_prompts[termname] = prompt
end

return M
