return function(settings, layout)
  local action = "sysinit_toggle_scratch"
  local label = "Sysinit scratch pane"

  rex.action({
    name = action,
    title = "Toggle floating scratch pane",
    run = function(ctx)
      local view = assert(rex.session.view({}))
      for _, window in ipairs(view.windows or {}) do
        if window.window_id == view.active_window_id then
          for _, layer in ipairs(window.layers or {}) do
            local blocks = layer.blocks or {}
            if layer.kind == "floating" and #blocks == 1 and blocks[1].label == label then
              local show = layer.state == "minimized"
              assert(rex.session.set_layer_state({
                layer_id = layer.layer_id,
                state = show and "normal" or "minimized",
                focus = show,
              }))
              return
            end
          end
        end
      end

      local process = ctx.block_id and rex.block.call("com.superlogical.terminal", "process", {})
      local directory = process and process.foreground and process.foreground.cwd
      assert(rex.session.new_layer({
        bounds = { 0.12, 0.12, 0.76, 0.76 },
        focus = true,
        layout = layout({ label = label, cwd = directory or settings.homeDirectory }),
      }))
    end,
  })
  rex.bind("cmd+f", action)
end
