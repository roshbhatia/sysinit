{
  lib,
  ...
}:

with lib;

{
  getUserHome =
    username: system:
    if hasPrefix "darwin" system then
      "/Users/${username}"
    else if hasPrefix "linux" system then
      "/home/${username}"
    else
      throw "Unsupported system: ${system}. Expected darwin or linux-based system";

  isDarwin = system: hasPrefix "darwin" system;
  isLinux = system: hasPrefix "linux" system;

  getAppsDirectory =
    system:
    if isDarwin system then
      "/Applications"
    else if isLinux system then
      "/usr/local/bin"
    else
      throw "Unsupported system: ${system}";

  getSystemLibraryPaths =
    system:
    if isDarwin system then
      [
        "/Library"
        "/System/Library"
      ]
    else if isLinux system then
      [
        "/usr/lib"
        "/usr/lib64"
      ]
    else
      throw "Unsupported system: ${system}";

  getDaemonConfigDir =
    system:
    if isDarwin system then
      "/Library/LaunchDaemons"
    else if isLinux system then
      "/etc/systemd/system"
    else
      throw "Unsupported system: ${system}";

  getServiceConfigPath =
    system: serviceName:
    let
      daemonDir = getDaemonConfigDir system;
    in
    if isDarwin system then
      "${daemonDir}/${serviceName}.plist"
    else if isLinux system then
      "${daemonDir}/${serviceName}.service"
    else
      throw "Unsupported system: ${system}";

  isValidPathForSystem =
    path: system:
    let
      isDarwinPath =
        hasPrefix "/Users/" path
        || hasPrefix "/Applications" path
        || hasPrefix "/Library" path
        || hasPrefix "/System/Library" path;
      isLinuxPath =
        hasPrefix "/home/" path
        || hasPrefix "/usr/" path
        || hasPrefix "/opt/" path
        || hasPrefix "/etc/" path;
      isUniversalPath =
        hasPrefix "~" path || hasPrefix "$" path || hasPrefix "/tmp" path || hasPrefix "/var" path;
    in
    if isDarwin system then
      isDarwinPath || isUniversalPath
    else if isLinux system then
      isLinuxPath || isUniversalPath
    else
      false;

  validatePathsForSystem =
    config: system: pathKeys:
    let
      invalidPaths = filter (
        key: hasAttr key config && !isValidPathForSystem config.${key} system
      ) pathKeys;
    in
    if length invalidPaths > 0 then
      throw "Paths invalid for system ${system}: ${concatStringsSep ", " invalidPaths}"
    else
      true;

  getArchitecture =
    system:
    let
      parts = builtins.split "-" system;
    in
    if length parts > 0 then elemAt parts 0 else system;

  getBrewArchitecture =
    system:
    let
      arch = getArchitecture system;
    in
    if arch == "aarch64" then
      "arm64"
    else if arch == "x86_64" then
      "x86_64"
    else
      arch;

  getBrewPrefix =
    system:
    if isDarwin system then
      let
        arch = getBrewArchitecture system;
      in
      if arch == "arm64" then "/opt/homebrew" else "/usr/local"
    else
      "/usr/local";

  getBrewBinDir = system: "${getBrewPrefix system}/bin";

  isX86_64 = system: getArchitecture system == "x86_64";

  isARM = system: getArchitecture system == "aarch64";
}
