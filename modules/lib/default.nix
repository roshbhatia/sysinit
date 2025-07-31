{
  lib,
  pkgs,
  system,
  ...
}:

with lib;

rec {
  paths = import ./paths { inherit lib; };
  platform = import ./platform.nix { inherit lib system; };
  shell = import ./shell { inherit lib; };
  theme = import ./theme-module.nix;
  themes = import ./themes { inherit lib; };
  packages = import ./packages.nix { inherit platform pkgs; };

  sysinit = {
    mkPackageManagerScript =
      manager: packages:
      ''
        if [ ${toString (length packages)} -gt 0 ]; then
          echo "Installing ${manager} packages: ${concatStringsSep " " packages}"
          if command -v ${manager} >/dev/null 2>&1; then
            for pkg in ${concatStringsSep " " packages}; do
              case "${manager}" in
                "cargo")
                  cargo install --locked "$pkg" || echo "Warning: Failed to install $pkg"
                  ;;
                "npm")
                  npm install -g "$pkg" || echo "Warning: Failed to install $pkg"
                  ;;
                "yarn")
                  yarn global add "$pkg" || echo "Warning: Failed to install $pkg"
                  ;;
                "pipx")
                  pipx install "$pkg" || echo "Warning: Failed to install $pkg"
                  ;;
                "go")
                  go install "$pkg" || echo "Warning: Failed to install $pkg"
                  ;;
                "uv")
                  uv tool install "$pkg" || echo "Warning: Failed to install $pkg"
                  ;;
                "kubectl")
                  kubectl krew install "$pkg" || echo "Warning: Failed to install $pkg"
                  ;;
                "gh")
                  gh extension install "$pkg" || echo "Warning: Failed to install $pkg"
                  ;;
                *)
                  echo "Unknown package manager: ${manager}"
                  ;;
              esac
            done
            echo "Completed ${manager} package installation"
          else
            echo "Warning: ${manager} not available, skipping package installation"
          fi
        fi
      '';

    mkXdgConfigFile =
      {
        name,
        content ? null,
        source ? null,
      }:
      let
        fileContent = if content != null then content else readFile source;
      in
      {
        "xdg.configFile.\"${name}\"" = {
          text = fileContent;
        };
      };

    mkSessionVars = vars: {
      home.sessionVariables = vars;
    };
  };

  mkPlatformConfig =
    {
      darwin ? { },
      linux ? { },
    }:
    if platform.platform.isDarwin then darwin else linux;

  mkOutOfStorePackage =
    {
      source,
      target ? null,
      name ? null,
    }:
    let
      targetPath = if target != null then target else name;
      linkName = if name != null then name else builtins.baseNameOf source;
    in
    pkgs.runCommand linkName { } ''
      mkdir -p $out/bin
      ln -sf ${source} $out/bin/${linkName}
    '';
}
