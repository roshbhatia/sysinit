{ config, lib, pkgs, ... }:

let
  activationUtils = import ../../lib/activation-utils.nix { inherit lib; };
in
{
  # Create a simple test activation script
  home.activation.testActivation = activationUtils.mkActivationScript {
    description = "Testing activation framework";
    after = [ "setupActivationUtils" ];
    script = ''
      log_info "Testing activation framework"
      log_debug "This is a debug message"
      log_success "Test successful"
      
      # Test command execution
      log_command "echo 'Hello from test activation'" "Echo test command"
      
      # Test executable checking
      check_executable "bash" && log_success "Bash is available"
      check_executable "nonexistentcommand" || log_error "Command not found (expected)"
    '';
  };
}
