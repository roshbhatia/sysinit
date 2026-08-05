local neoconf = require("neoconf")

local base_config = {
  root_markers = {
    "docker-compose.yml",
    "docker-compose.yaml",
    "compose.yml",
    "compose.yaml",
    ".git",
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("docker_compose_language_service") or {})
