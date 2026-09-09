{
  xdg.configFile."tether/config.json".text = builtins.toJSON {
    mode = "auto";
    flaky = {
      rtt_ms = 60;
      loss = 0;
    };
    hosts = { };
  };
}
