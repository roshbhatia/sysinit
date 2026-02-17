_:

{
  stylix.targets.ghostty = {
    enable = true;
  };

  programs.ghostty = {
    enable = true;
    settings = {
      keybind = [
        "alt+v=activate_key_table:vim"

        # Key table definition
        "vim/"

        # Line movement
        "vim/j=scroll_page_lines:1"
        "vim/k=scroll_page_lines:-1"

        # Page movement
        "vim/ctrl+d=scroll_page_down"
        "vim/ctrl+u=scroll_page_up"
        "vim/ctrl+f=scroll_page_down"
        "vim/ctrl+b=scroll_page_up"
        "vim/shift+j=scroll_page_down"
        "vim/shift+k=scroll_page_up"

        # Jump to top/bottom
        "vim/g>g=scroll_to_top"
        "vim/shift+g=scroll_to_bottom"

        # Search
        "vim/slash=start_search"
        "vim/n=navigate_search:next"

        # Copy mode / selection
        "vim/v=copy_to_clipboard"
        "vim/y=copy_to_clipboard"

        # Command Palette
        "vim/shift+semicolon=toggle_command_palette"

        # Exit vim mode
        "vim/escape=deactivate_key_table"
        "vim/q=deactivate_key_table"
        "vim/i=deactivate_key_table"

        # Catch unbound keys
        "vim/catch_all=ignore"
      ];
    };
  };
}
