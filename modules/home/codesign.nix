{
  config,
  lib,
  pkgs,
  ...
}:
let
  paths = import ../shared/codesign.nix;
  cfg = config.sysinit.codesign;

  home = config.home.homeDirectory;
  keychain = "${home}/Library/Keychains/${paths.keychainName}";
  passwordFile = "${home}/${paths.passwordFile}";
  certFile = "${home}/${paths.certFile}";
  signedBinDir = "${home}/${paths.signedBinDir}";

  stageCommands = lib.concatMapStringsSep "\n" (
    name: "stage ${lib.escapeShellArg name} ${lib.escapeShellArg cfg.binaries.${name}}"
  ) (builtins.attrNames cfg.binaries);

  signerScript =
    builtins.replaceStrings
      [
        "@keychain@"
        "@passwordFile@"
        "@certFile@"
        "@signedBinDir@"
        "@identity@"
        "@stageCommands@"
      ]
      [
        (lib.escapeShellArg keychain)
        (lib.escapeShellArg passwordFile)
        (lib.escapeShellArg certFile)
        (lib.escapeShellArg signedBinDir)
        (lib.escapeShellArg paths.identity)
        stageCommands
      ]
      (builtins.readFile ./codesign.sh.tmpl);

  signer = pkgs.writeShellApplication {
    name = "sysinit-codesign";
    runtimeInputs = [ pkgs.openssl ];
    text = signerScript;
  };
in
{
  options.sysinit.codesign = {
    enable = lib.mkEnableOption "a stable code-signing identity so TCC grants survive a rebuild" // {
      default = pkgs.stdenv.hostPlatform.isDarwin;
    };

    binaries = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Executables that launchd starts and that need a TCC permission, as
        name -> store path. Each is copied to a path that does not move and
        signed there, so its grant survives the next update.
      '';
      example = lib.literalExpression ''{ borders = "''${pkgs.jankyborders}/bin/borders"; }'';
    };

    signedBinDir = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = signedBinDir;
      description = "Where the staged, signed copies live. Point launchd here.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = signer;
      description = "The signer. Run it with `system` from a root activation step.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.sysinitCodesign = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe signer} || true
    '';
  };
}
