local M = {}

local last_prompts = {}

-- Wait for pane to be available before sending (with exponential backoff)
function M.ensure_terminal_and_send(termname, text)
  last_prompts[termname] = text

  local session = require("sysinit.utils.ai.session")
  local term_info = session.get_info(termname)

  if not term_info or not term_info.visible then
    session.open(termname)
    session.focus(termname)

    -- Poll for pane to be ready with exponential backoff
    local max_retries = 15
    local retry = 0
    local backoff_ms = 25
    
    while retry < max_retries do
      if session.is_visible(termname) then
        -- Terminal is ready, send immediately
        session.send(termname, text, { submit = true })
        return
      end
      
      -- Exponential backoff: 25ms, 50ms, 100ms, ...
      vim.fn.system(string.format("sleep %.3f", backoff_ms / 1000))
      backoff_ms = math.min(backoff_ms * 1.5, 200)
      retry = retry + 1
    end

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
