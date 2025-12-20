{ pkgs }:

{
  gh = {
    bin = "${pkgs.gh}/bin/gh";
    env = ''
      export PATH="${pkgs.gh}/bin:/usr/bin:$PATH"
      export GH_FORCE_TTY=false
    '';
    installCmd = ''
      if output=$("$MANAGER_CMD" extension install "$pkg" 2>&1); then
        true
      else
        case "$output" in
          *"there is already an installed extension that provides"*)
            echo "Extension already installed: $pkg"
            ;;
          *)
            echo "Warning: Failed to install $pkg"
            ;;
        esac
      fi
    '';
  };
}
