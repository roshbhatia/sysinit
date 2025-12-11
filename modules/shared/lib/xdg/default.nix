{
  lib,
  pkgs,
}:
let
  mkWritableXdgConfig =
    {
      config,
      path,
      text,
      executable ? false,
      force ? false,
    }:
    let
      activationName = "writable-${builtins.replaceStrings [ "/" "." ] [ "-" "-" ] path}";

      sourceFile = pkgs.writeText "${activationName}-source" text;

      xdgConfigHome = config.xdg.configHome;

      copyScript =
        if force then
          ''
            DEST_PATH="${xdgConfigHome}/${path}"
            $DRY_RUN_CMD mkdir -p "$(dirname "$DEST_PATH")"
            $DRY_RUN_CMD echo "Installing writable config: ${path}"

            # Remove legacy backup files
            for backup_ext in .nix-prev .bak .backup; do
              [[ -f "$DEST_PATH$backup_ext" ]] && $DRY_RUN_CMD rm -f "$DEST_PATH$backup_ext"
            done

            $DRY_RUN_CMD cp -f "${sourceFile}" "$DEST_PATH"
            ${if executable then ''$DRY_RUN_CMD chmod +x "$DEST_PATH"'' else ""}
          ''
        else
          ''
            DEST_PATH="${xdgConfigHome}/${path}"
            $DRY_RUN_CMD mkdir -p "$(dirname "$DEST_PATH")"

            # Remove legacy backup files
            for backup_ext in .nix-prev .bak .backup; do
              [[ -f "$DEST_PATH$backup_ext" ]] && $DRY_RUN_CMD rm -f "$DEST_PATH$backup_ext"
            done

            # Check if destination exists and is not a symlink
            if [[ -f "$DEST_PATH" && ! -L "$DEST_PATH" ]]; then
              # File exists - check if source changed
              if ! cmp -s "${sourceFile}" "$DEST_PATH"; then
                $DRY_RUN_CMD echo "Config source changed, updating: ${path}"
                $DRY_RUN_CMD cp -f "${sourceFile}" "$DEST_PATH"
                ${if executable then ''$DRY_RUN_CMD chmod +x "$DEST_PATH"'' else ""}
              else
                $DRY_RUN_CMD echo "Config unchanged, preserving: ${path}"
              fi
            else
              # First install or was a symlink
              $DRY_RUN_CMD echo "Installing new writable config: ${path}"
              if [[ -L "$DEST_PATH" ]]; then
                $DRY_RUN_CMD rm "$DEST_PATH"
              fi
              $DRY_RUN_CMD cp "${sourceFile}" "$DEST_PATH"
              ${if executable then ''$DRY_RUN_CMD chmod +x "$DEST_PATH"'' else ""}
            fi
          '';
    in
    {
      source = sourceFile;
      script = copyScript;
    };

  mkWritableXdgConfigs =
    configs:
    let
      results = builtins.map mkWritableXdgConfig configs;
    in
    {
      activations = builtins.listToAttrs (
        lib.imap0 (i: result: {
          name = "writable-config-${toString i}";
          value = result.script;
        }) results
      );
    };
in
{
  inherit mkWritableXdgConfig mkWritableXdgConfigs;
}
