{ lib }:
let
  readSource = name: builtins.readFile (./. + "/${name}");

  renderTemplate =
    template: substitutions:
    let
      names = builtins.attrNames substitutions;
    in
    lib.replaceStrings (map (name: "@${name}@") names) (map (
      name: substitutions.${name}
    ) names) template;

  mergeProgram = readSource "managed-file-merge3.jq";

  formats = [
    "json"
    "yaml"
    "toml"
  ];

  mkCapture =
    { pkgs, files }:
    let
      enabled = lib.filterAttrs (_: file: file.enable) files;
      captureFile = pkgs.writeText "managed-file-capture.jq" (readSource "managed-file-capture.jq");
      mkCase =
        name: file:
        "  ${lib.escapeShellArg name})\n    capture ${lib.escapeShellArg name} ${lib.escapeShellArg file.path} ${file.format}\n    ;;";
    in
    pkgs.writeShellApplication {
      name = "sysinit-llm-capture";
      runtimeInputs = [
        pkgs.jq
        pkgs.yq-go
      ];
      text = renderTemplate (readSource "managed-file-capture.sh.tmpl") {
        NAMES = lib.concatStringsSep "\n" (
          map (name: "  ${lib.escapeShellArg name}") (builtins.attrNames enabled)
        );
        CAPTURE_FILE = toString captureFile;
        CASES = lib.concatStringsSep "\n" (lib.mapAttrsToList mkCase enabled);
        CAPTURE_DIRECTIVE = lib.optionalString (enabled == { }) "# shellcheck disable=SC2329\n";
      };
    };

  mkReconciler =
    { pkgs, files }:
    let
      enabled = lib.filterAttrs (_: file: file.enable) files;
      disabled = lib.filterAttrs (_: file: !file.enable) files;

      mergeFile = pkgs.writeText "managed-file-merge3.jq" mergeProgram;
      adoptFile = pkgs.writeText "managed-file-adopt.jq" (readSource "managed-file-adopt.jq");
      applyEnforcedFile = pkgs.writeText "managed-file-apply-enforced.jq" (
        readSource "managed-file-apply-enforced.jq"
      );

      mkCall =
        name: file:
        let
          declaredFile =
            if file.contentFile != null then
              file.contentFile
            else
              pkgs.writeText "managed-${name}-new.json" (builtins.toJSON file.content);
        in
        lib.concatStringsSep " " [
          "reconcile"
          (lib.escapeShellArg name)
          (lib.escapeShellArg file.path)
          file.format
          declaredFile
          (if file.contentFile != null then file.format else "json")
          (if file.schema == null then "-" else file.schema)
          (lib.escapeShellArg (
            builtins.toJSON (map (path: if builtins.isList path then path else [ path ]) file.enforce)
          ))
          (lib.escapeShellArg (
            builtins.toJSON (map (path: if builtins.isList path then path else [ path ]) file.retire)
          ))
          (if file.createIfMissing then "create" else "skip")
        ];

      mkForget = _name: file: "forget_base ${lib.escapeShellArg file.path}";
      unusedDirective = "# shellcheck disable=SC2329";
    in
    pkgs.writeShellApplication {
      name = "sysinit-llm-reconcile";
      runtimeInputs = [
        pkgs.jq
        pkgs.yq-go
        pkgs.check-jsonschema
      ];
      text = renderTemplate (readSource "managed-file-reconcile.sh.tmpl") {
        EMPTY_MANAGED_COMMENT = lib.optionalString (
          enabled == { }
        ) "# Every managed file is disabled, so only base cleanup runs.\n";
        RECONCILE_HELPER_DIRECTIVE = lib.optionalString (enabled == { }) "${unusedDirective}\n";
        FORGET_DIRECTIVE = lib.optionalString (disabled == { }) "${unusedDirective}\n";
        ADOPT_FILE = toString adoptFile;
        APPLY_ENFORCED_FILE = toString applyEnforcedFile;
        MERGE_FILE = toString mergeFile;
        FORGET_CALLS = lib.concatStringsSep "\n" (lib.mapAttrsToList mkForget disabled);
        RECONCILE_CALLS = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: file: "${mkCall name file} || result=1") enabled
        );
      };
    };
in
{
  inherit
    mergeProgram
    formats
    mkCapture
    mkReconciler
    ;
}
