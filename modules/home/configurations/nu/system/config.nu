#!/usr/bin/env nu
# shellcheck disable=all
$env.config = {
  show_banner: false
  edit_mode: "vi"
  cursor_shape: {
    vi_insert: underscore
    vi_normal: block
  }
  history: {
    max_size: 50000
    sync_on_enter: true
    file_format: "plaintext"
    isolation: false
  }
  menus: [
    {
      name: completion_menu
      only_buffer_difference: false
      marker: "| "
      type: {
        layout: columnar
        columns: 4
        col_width: 20
        col_padding: 2
      }
      style: {
        text: green
        selected_text: green_reverse
        description_text: yellow
      }
    }
  ]
  keybindings: [
    {
      name: completion_menu
      modifier: none
      keycode: tab
      mode: [emacs vi_normal vi_insert]
      event: {
        until: [
          { send: menu name: completion_menu }
          { send: menunext }
          { edit: complete }
        ]
      }
    }
    {
      name: history_menu
      modifier: control
      keycode: char_r
      mode: [emacs vi_insert vi_normal]
      event: { send: menu name: history_menu }
    }
    {
      name: help_menu
      modifier: none
      keycode: f1
      mode: [emacs vi_insert vi_normal]
      event: { send: menu name: help_menu }
    }
  ]
}

