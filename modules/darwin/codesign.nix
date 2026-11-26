{
  config,
  lib,
  pkgs,
  ...
}:
let
  paths = import ../shared/codesign.nix;
  user = config.sysinit.user.username;
  appState = "${lib.getExe pkgs.nushell} --no-config-file ${../home/app-copy-state.nu}";
  appStateArgs = lib.escapeShellArgs [
    "${config.system.build.applications}/Applications"
    "/Applications/Nix Apps"
    "/var/db/sysinit/app-copy.json"
  ];
  signedBin = "${config.users.users.${user}.home}/${paths.signedBinDir}";

  stable =
    name: pkg:
    pkgs.symlinkJoin {
      name = "${name}-stable-path";
      paths = [ pkg ];
      postBuild = ''
        rm -f "$out/bin/${name}"
        ln -s "${signedBin}/${name}" "$out/bin/${name}"
      '';
    };
in
{
  # nix-darwin's check runs before activationScripts.applications. Keep its
  # permission check for actual changes without discarding existing decisions.
  options.system.checks.text = lib.mkOption {
    apply =
      text:
      let
        upstreamGuard = "\nif ! ensureAppManagement; then\n";
        upstreamReset = "tccutil reset SystemPolicyAppBundles > /dev/null";
      in
      assert lib.assertMsg (
        lib.hasInfix upstreamGuard text && lib.hasInfix upstreamReset text
      ) "Review the Sysinit App Management override after updating nix-darwin.";
      builtins.replaceStrings
        [
          upstreamGuard
          "    # The TCC service required to modify notarised app bundles is `kTCCServiceSystemPolicyAppBundles`\n"
          "    # and we can reset it to ensure the user gets another prompt\n"
          "    ${upstreamReset}\n"
        ]
        [
          "\nif ! ${appState} check ${appStateArgs} && ! ensureAppManagement; then\n"
          ""
          ""
          ""
        ]
        text;
  };

  config = {
    home-manager.users.${user}.sysinit.codesign.binaries = {
      borders = "${pkgs.jankyborders}/bin/borders";
      sketchybar = "${pkgs.sketchybar}/bin/sketchybar";
    };

    services.jankyborders.package = lib.mkForce (stable "borders" pkgs.jankyborders);
    services.sketchybar.package = lib.mkForce (stable "sketchybar" pkgs.sketchybar);

    system.activationScripts.postActivation.text = ''
      SYSINIT_APPS_VALIDATED="''${sysinit_system_apps_validated:-0}" ${
        lib.getExe config.home-manager.users.${user}.sysinit.codesign.package
      } system
      if [ "''${sysinit_system_apps_validated:-0}" != 1 ]; then
        ${appState} record ${appStateArgs} || echo "sysinit: app signatures need repair" >&2
      fi
      ${lib.optionalString config.services.jankyborders.enable ''
        borders_domain="gui/$(id -u ${lib.escapeShellArg user})/org.nixos.jankyborders"
        borders_marker="/var/db/sysinit/jankyborders-package"
        if [ "$(cat "$borders_marker" 2>/dev/null)" != "${pkgs.jankyborders}" ] &&
          launchctl print "$borders_domain" >/dev/null 2>&1; then
          if launchctl kickstart -k "$borders_domain"; then
            mkdir -p /var/db/sysinit
            printf '%s\n' "${pkgs.jankyborders}" > "$borders_marker"
          else
            echo "sysinit: failed to restart the signed borders binary" >&2
            exit 1
          fi
        fi
      ''}
    '';

    system.activationScripts.applications.text = lib.mkMerge [
      (lib.mkBefore ''
        sysinit_system_apps_validated=0
        if ${appState} check ${appStateArgs}; then
          sysinit_system_apps_validated=1
        else
      '')
      (lib.mkAfter ''
        fi
      '')
    ];
  };
}
