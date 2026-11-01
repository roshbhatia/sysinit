{
  config,
  lib,
  pkgs,
  ...
}:
let
  bundleIdentifier = "org.sysinit.neovim-file-opener";
  app = "${config.home.homeDirectory}/Applications/Sysinit Neovim.app";
  extensions = [
    "gitattributes"
    "gitconfig"
    "gitignore"
    "asp"
    "aspx"
    "cshtml"
    "jshtm"
    "jsp"
    "phtml"
    "bat"
    "cmd"
    "bowerrc"
    "config"
    "editorconfig"
    "ini"
    "cfg"
    "cs"
    "csx"
    "css"
    "go"
    "jade"
    "jav"
    "java"
    "js"
    "jscsrc"
    "jshintrc"
    "mjs"
    "cjs"
    "json"
    "less"
    "markdown"
    "md"
    "mdoc"
    "mdown"
    "mdtext"
    "mdtxt"
    "mdwn"
    "mkd"
    "mkdn"
    "php"
    "ps1"
    "psd1"
    "psm1"
    "py"
    "pyi"
    "gemspec"
    "rb"
    "erb"
    "scss"
    "sass"
    "sql"
    "ts"
    "tsx"
    "jsx"
    "vue"
    "ascx"
    "csproj"
    "dtd"
    "wxi"
    "wxl"
    "wxs"
    "xaml"
    "eyaml"
    "eyml"
    "yaml"
    "yml"
    "bash_login"
    "bash_logout"
    "bash_profile"
    "bashrc"
    "profile"
    "rhistory"
    "rprofile"
    "sh"
    "zlogin"
    "zlogout"
    "zprofile"
    "zshenv"
    "zshrc"
    "clj"
    "cljs"
    "cljx"
    "clojure"
    "code-workspace"
    "coffee"
    "cmake"
    "dart"
    "diff"
    "dockerfile"
    "gradle"
    "groovy"
    "makefile"
    "lua"
    "pug"
    "ipynb"
    "lock"
    "log"
    "vb"
    "rs"
    "rst"
    "tex"
    "cls"
    "fsi"
    "fsx"
    "fsscript"
    "svg"
    "toml"
    "nix"
    "cue"
  ];
  extensionPlist = lib.concatMapStringsSep "\n" (
    extension: "<string>${extension}</string>"
  ) extensions;
  plist = pkgs.writeText "sysinit-neovim-file-opener-Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0"><dict>
      <key>CFBundleDevelopmentRegion</key><string>en</string>
      <key>CFBundleExecutable</key><string>sysinit-neovim-file-opener</string>
      <key>CFBundleIdentifier</key><string>${bundleIdentifier}</string>
      <key>CFBundleName</key><string>Sysinit Neovim</string>
      <key>CFBundlePackageType</key><string>APPL</string>
      <key>CFBundleShortVersionString</key><string>1</string>
      <key>CFBundleVersion</key><string>1</string>
      <key>LSUIElement</key><true/>
      <key>CFBundleDocumentTypes</key><array><dict>
        <key>CFBundleTypeName</key><string>Source and configuration file</string>
        <key>CFBundleTypeRole</key><string>Editor</string>
        <key>LSHandlerRank</key><string>Owner</string>
        <key>CFBundleTypeExtensions</key><array>${extensionPlist}</array>
      </dict></array>
    </dict></plist>
  '';
  source = pkgs.writeText "sysinit-neovim-file-opener.swift" (
    builtins.replaceStrings
      [ "@WEZTERM@" "@NVIM@" "@BUNDLE_ID@" "@EXTENSIONS@" ]
      [
        "${config.home.profileDirectory}/bin/wezterm"
        "${config.home.profileDirectory}/bin/nvim"
        bundleIdentifier
        (lib.concatStringsSep " " extensions)
      ]
      (builtins.readFile ./neovim-file-opener.swift)
  );
in
{
  home.activation.sysinitDefaultApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    app=${lib.escapeShellArg app}
    run mkdir -p "$app/Contents/MacOS"
    run cp ${lib.escapeShellArg (toString plist)} "$app/Contents/Info.plist"
    run /usr/bin/swiftc -O -framework AppKit -framework CoreServices -framework UniformTypeIdentifiers \
      ${lib.escapeShellArg (toString source)} \
      -o "$app/Contents/MacOS/sysinit-neovim-file-opener"
    run /usr/bin/codesign --force --deep --sign - --timestamp=none "$app"
    run /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
      -f "$app"
    run "$app/Contents/MacOS/sysinit-neovim-file-opener" --set-defaults
  '';
}
