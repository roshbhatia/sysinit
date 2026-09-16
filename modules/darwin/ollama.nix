{
  config,
  ...
}:

{
  launchd.user.agents.ollama = {
    serviceConfig = {
      Label = "com.ollama.default";
      ProgramArguments = [
        "${config.homebrew.prefix}/bin/ollama"
        "serve"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/ollama.log";
      StandardErrorPath = "/tmp/ollama.error.log";
      EnvironmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "65536";

        OLLAMA_KEEP_ALIVE = "-1";
      };
    };
  };
}
