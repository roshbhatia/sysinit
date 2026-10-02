rec {
  name = "bulk-read";
  schema = "${name}-result";

  provider = "claude";
  model = "light";
  reader = "ask -t ${name}";
}
