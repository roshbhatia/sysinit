_: {
  programs.ssh = {
    extraConfig = ''
      # Include Lima VM SSH configs - must come BEFORE Host blocks
      Include ~/.lima/*/ssh.config

      IdentityAgent ~/.1password/agent.sock
    '';
  };
}
