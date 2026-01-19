return {
  {
    "someone-stole-my-name/yaml-companion.nvim",
    ft = { "yaml", "yaml.docker-compose", "yaml.ansible" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("telescope").load_extension("yaml_schema")

      require("yaml-companion").setup({
        builtin_matchers = {
          cloud_init = { enabled = false },
          docker_compose = { enabled = true },
          github_workflow = { enabled = true },
          gitlab = { enabled = false },
          kubernetes = { enabled = true },
        },
        schemas = {
          result = {
            {
              name = "Kubernetes",
              uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/master-standalone-strict/all.json",
            },
            {
              name = "Kustomization",
              uri = "https://json.schemastore.org/kustomization.json",
            },
            {
              name = "GitHub Workflow",
              uri = "https://json.schemastore.org/github-workflow.json",
            },
            {
              name = "Helm Chart",
              uri = "https://json.schemastore.org/chart.json",
            },
          },
        },
        lspconfig = {
          flags = {
            debounce_text_changes = 150,
          },
          settings = {
            redhat = {
              telemetry = {
                enabled = false,
              },
            },
            yaml = {
              validate = true,
              format = { enable = true },
              hover = true,
              schemaStore = {
                enable = true,
                url = "https://www.schemastore.org/api/json/catalog.json",
              },
              schemas = {
                kubernetes = "k8s/**/*.yaml",
                ["https://json.schemastore.org/kustomization.json"] = "kustomization.yaml",
              },
            },
          },
        },
      })
    end,
  },
}
