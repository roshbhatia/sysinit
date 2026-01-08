if (which wezterm | is-not-empty) {
  $env.config.hooks.env_change.PWD = (
    $env.config.hooks.env_change.PWD?
    | default []
    | append { ||
        try { wezterm set-working-directory } catch { }
      }
  )
}
