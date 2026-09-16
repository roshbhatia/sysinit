final: _prev:
let
  formatShell =
    drv:
    drv.overrideAttrs (old: {
      checkPhase = ''
        ${final.shfmt}/bin/shfmt -ln bash -i 2 -ci -sr -s -w "$target"
      ''
      + (old.checkPhase or "");
    });
in
{
  sysinit = {
    writeShellApplication = args: formatShell (final.writeShellApplication args);
    writeShellScript = name: text: formatShell (final.writeShellScript name text);
    writeShellScriptBin = name: text: formatShell (final.writeShellScriptBin name text);
    writeJSON = name: value: (final.formats.json { }).generate name value;
  };
}
