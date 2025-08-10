{
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit (values) lib; };

  appStylixTargets = themes.stylixHelpers.enableStylixTargets [
    "vscode"
    "firefox"
  ];

in

appStylixTargets
