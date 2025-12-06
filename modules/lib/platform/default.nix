{
  lib,
  ...
}:

with lib;

{
  /*
    Platform-specific path utilities.

    Provides normalized access to platform-dependent paths to ensure
    portability across macOS, Linux, and other platforms.
  */

  /*
    Get the home directory path for a user.

    Arguments:
      username: string - Username
      system: string - System type (aarch64-darwin, x86_64-linux, etc.)

    Returns:
      string - Absolute home directory path
  */
  getUserHome =
    username: system:
    if hasPrefix "darwin" system then
      "/Users/${username}"
    else if hasPrefix "linux" system then
      "/home/${username}"
    else
      throw "Unsupported system: ${system}. Expected darwin or linux-based system";

  /*
    Determine if a system is macOS.

    Arguments:
      system: string - System type

    Returns:
      bool - True if macOS/darwin
  */
  isDarwin = system: hasPrefix "darwin" system;

  /*
    Determine if a system is Linux.

    Arguments:
      system: string - System type

    Returns:
      bool - True if linux
  */
  isLinux = system: hasPrefix "linux" system;

  /*
    Get the applications directory path.

    Arguments:
      system: string - System type

    Returns:
      string - Absolute applications directory path
  */
  getAppsDirectory =
    system:
    if isDarwin system then
      "/Applications"
    else if isLinux system then
      "/usr/local/bin"
    else
      throw "Unsupported system: ${system}";

  /*
    Get the system library paths.

    Arguments:
      system: string - System type

    Returns:
      list - System library paths for the platform
  */
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

  /*
    Get daemon configuration directory.

    Arguments:
      system: string - System type

    Returns:
      string - Path to daemon configuration directory
  */
  getDaemonConfigDir =
    system:
    if isDarwin system then
      "/Library/LaunchDaemons"
    else if isLinux system then
      "/etc/systemd/system"
    else
      throw "Unsupported system: ${system}";

  /*
    Get configuration directory name for a service.

    Arguments:
      system: string - System type
      serviceName: string - Service/daemon name

    Returns:
      string - Full path to service configuration
  */
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

  /*
    Validate a path is appropriate for the target system.

    Arguments:
      path: string - Path to validate
      system: string - Target system type

    Returns:
      bool - True if path is valid for system
  */
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

  /*
    Validate all paths in configuration are valid for the target system.

    Arguments:
      config: attrs - Configuration with path references
      system: string - Target system type
      pathKeys: list - Keys to check for paths

    Returns:
      bool - True if all paths are valid
  */
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
}
