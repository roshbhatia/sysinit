{pkgs, lib, config, userConfig ? {}, ...}:

let
  additionalPackages = if userConfig ? pipx && userConfig.pipx ? additionalPackages
                      then userConfig.pipx.additionalPackages
                      else [];

  basePackages = [];

  allPackages = basePackages ++ additionalPackages;
in
{
  # Instead of using home-manager's pipx module, create an activation script
  home.activation.pipxPackages = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      # Install packages using pipx if they're not already installed
      for package in ${lib.escapeShellArgs allPackages}; do
        if ! pipx list | grep -q "$package"; then
          echo "Installing $package with pipx..."
          pipx install "$package"
        fi
      done
    '';
  };
}