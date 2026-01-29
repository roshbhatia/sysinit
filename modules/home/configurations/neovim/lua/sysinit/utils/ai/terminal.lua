local M = {}

local last_prompts = {}

-- Wait for pane to be available before sending (polling instead of defer)
function M.ensure_terminal_and_send(termname, text)
  last_prompts[termname] = text

  local session = require("sysinit.utils.ai.session")
  local term_info = session.get_info(termname)

  if not term_info or not term_info.visible then
    session.open(termname)
    session.focus(termname)

    -- Poll for pane to be ready (instead of arbitrary defer delay)
    local max_retries = 10
    local retry = 0
    while retry < max_retries do
      vim.fn.system("sleep 0.05")
      if session.is_visible(termname) then
        session.send(termname, text, { submit = true })
        return
      end
      retry = retry + 1
    end

    -- If we get here, pane never became visible
    vim.notify("Pane failed to become ready for sending text", vim.log.levels.ERROR)
  else
    session.focus(termname)
    -- Already visible, send immediately
    session.send(termname, text, { submit = true })
  end
end

function M.get_last_prompt(termname)
  return last_prompts[termname]
end

function M.set_last_prompt(termname, prompt)
  last_prompts[termname] = prompt
end

return M
