{
  lib,
  config,
  ...
}:

{
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };

  # Clean up stale theme symlinks from previous configurations
  # Stylix now manages bat themes automatically via base16-stylix.tmTheme
  home.activation.cleanupBatThemes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run rm -f ${config.xdg.configHome}/bat/themes/kanagawa-lotus.tmTheme
  '';
}
