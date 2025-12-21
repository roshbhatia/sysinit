_:

{
  home.file.".local/share/nemo/actions/open-terminal.nemo_action" = {
    text = ''
      [Nemo Action]
      Active=true
      Name=Open Terminal Here
      Exec=wezterm -e bash -c "cd %f && bash"
      Selection=Any
      Extensions=any;
    '';
  };

  dconf.settings = {
    "org/cinnamon/desktop/default-applications/terminal" = {
      exec = "wezterm";
    };

    "org/nemo/preferences" = {
      show-hidden-files = false;
      show-advanced-permissions = true;
      date-format = "informal";
      default-folder-viewer = "icon-view";
    };

    "org/nemo/window-state" = {
      geometry = "1200x800+50+50";
      sidebar-width = 200;
    };
  };

}
