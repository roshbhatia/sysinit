{ lib, ... }:

let
  defaultPaths = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/usr/bin"
    "/usr/local/opt/cython/bin"
    "/usr/sbin"
    "$HOME/.krew/bin"
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
    "$HOME/.npm-global/bin/yarn"
    "$HOME/.rvm/bin"
    "$HOME/.yarn/bin"
    "$HOME/bin"
    "$HOME/go/bin"
    "$XDG_CONFIG_HOME/.cargo/bin"
    "$XDG_CONFIG_HOME/yarn/global/node_modules/.bin"
    "$XDG_CONFIG_HOME/zsh/bin"
    "$HOME/.uv/bin"
    "$HOME/.yarn/global/node_modules/.bin"
    "$HOME/.cargo/bin"
    "/bin"
    "/sbin"
  ];
in {
  /**
   * Creates an activation utils module that provides PATH management and logging functions
   * 
   * This function must be called early in the activation setup to ensure PATH and logging 
   * are available for all subsequent activations.
   */
  mkActivationUtils = {
    name ? "setupActivationUtils",
    logDir ? "/tmp/log",
    logPrefix ? "sysinit",
    additionalPaths ? [],
  }: let
    allPaths = lib.unique (defaultPaths ++ additionalPaths);
    escapedPaths = lib.concatStringsSep ":" allPaths;
  in {
    home.activation.${name} = {
      # Ensure this runs first, before other activation scripts
      after = [];
      before = [ "*" ];
      data = ''
        ########## PATH SETUP ##########
        export PATH="${escapedPaths}:$PATH"
        
        ########## LOGGING SETUP ##########
        LOG_DIR="${logDir}"
        LOG_PREFIX="${logPrefix}"
        mkdir -p "$LOG_DIR"
        
        log_info() {
          echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;34mINFO\033[0m] $1"
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_DIR/${logPrefix}.log"
        }
        
        log_debug() {
          echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;35mDEBUG\033[0m] $1"
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $1" >> "$LOG_DIR/${logPrefix}.log"
        }
        
        log_error() {
          echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;31mERROR\033[0m] $1"
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_DIR/${logPrefix}.log"
        }
        
        log_success() {
          echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;32mSUCCESS\033[0m] $1"
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "$LOG_DIR/${logPrefix}.log"
        }
        
        log_command() {
          local cmd="$1"
          local description="$2"
          log_info "Running: $description"
          
          # Execute the command and capture its output
          local output
          if output=$(eval "$cmd" 2>&1); then
            log_success "$description completed"
            [ -n "$output" ] && echo "$output"
            return 0
          else
            local exit_code=$?
            log_error "$description failed with exit code $exit_code"
            [ -n "$output" ] && echo "$output"
            return $exit_code
          fi
        }
        
        check_executable() {
          local executable="$1"
          if ! command -v "$executable" &> /dev/null; then
            log_error "$executable not found in PATH"
            return 1
          fi
          log_debug "Found $executable at $(command -v "$executable")"
          return 0
        }
        
        log_debug "Activation utilities initialized"
        log_debug "PATH: $PATH"
      '';
    };
  };
  
  /**
   * Creates a package manager activation script
   * 
   * Requires the activation utils to be set up first
   */
  mkPackageManager = {
    name,
    basePackages,
    additionalPackages ? [],
    executableArguments,
    executablePath,
    logFailures ? true,
    skipIfMissing ? false,
  }: let
    allPackages = basePackages ++ additionalPackages;
    escapedPackages = lib.concatStringsSep " " (map lib.escapeShellArg allPackages);
    escapedArguments = lib.concatStringsSep " " (map lib.escapeShellArg executableArguments);
  in {
    # Make sure this runs after the activation utils
    home.activation."${name}Packages" = {
      after = [ "setupActivationUtils" ];
      before = [];
      data = ''
        log_info "Managing ${name} packages..."
        
        # Check if executable exists
        if check_executable "${executablePath}"; then
          EXECUTABLE="${executablePath}"
          PACKAGES='${escapedPackages}'
          
          if [ -n "$PACKAGES" ]; then
            for package in $PACKAGES; do
              log_command "$EXECUTABLE ${escapedArguments} $package" "Installing $package via ${name}"
            done
            log_success "All ${name} packages processed"
          else
            log_info "No ${name} packages specified"
          fi
        else
          ${if skipIfMissing then ''
            log_info "${name} not found at ${executablePath} - skipping package installation"
          '' else ''
            log_error "${name} not found at ${executablePath}"
            ${if logFailures then "exit 1" else ""}
          ''}
        fi
      '';
    };
  };
  
  /**
   * Creates a custom activation script that uses the activation utils
   */
  mkActivationScript = {
    name,
    description ? name,
    script,
    requiredExecutables ? [],
    after ? [ "setupActivationUtils" ],
    before ? [],
  }: {
    home.activation.${name} = {
      inherit after before;
      data = ''
        log_info "Starting: ${description}"
        
        # Check required executables
        ${lib.concatMapStrings (exe: ''
          if ! check_executable "${exe}"; then
            log_error "Required executable ${exe} not found"
            exit 1
          fi
        '') requiredExecutables}
        
        # Run the script
        ${script}
        
        log_success "${description} completed"
      '';
    };
  };
}
