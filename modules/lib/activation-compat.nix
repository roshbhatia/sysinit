{ lib, config, ... }:

{
  # Override home-manager's checkLinkTargets activation script to work on macOS
  home.activation.checkLinkTargets = lib.mkForce {
    after = [];
    before = [ "linkGeneration" ];
    data = ''
      # BSD-compatible symlink checking for macOS
      function checkLinkTargets() {
        local errors=0
        local linkPath="$1"
        
        if [[ -e "$linkPath" && ! -L "$linkPath" ]]; then
          echo "Existing file '$linkPath' is in the way of a home-manager link"
          errors=$((errors + 1))
        fi
        
        return $errors
      }
      
      typeset -a targetPaths=()
      
      # Add all files to be linked
      while read -r line; do
        targetPaths+=("$line")
      done < <(cat "${config.home.homeDirectory}/.home-manager-files" 2>/dev/null || true)
      
      if [[ $#{targetPaths[@]} -ne 0 ]]; then
        echo "Checking link targets..."
        
        # Check all link targets
        errors=0
        for targetPath in "''${targetPaths[@]}"; do
          checkLinkTargets "$targetPath" || errors=$((errors + 1))
        done
        
        if [[ $errors -gt 0 ]]; then
          echo "$errors errors found while checking link targets. Aborting activation."
          exit 1
        fi
      fi
    '';
  };
}
