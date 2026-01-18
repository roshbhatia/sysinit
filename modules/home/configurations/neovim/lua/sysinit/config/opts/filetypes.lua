local M = {}

function M.setup()
  vim.filetype.add({
    extension = {
      h = "c",
      -- Go templates (can be helm, go templates, etc.)
      tmpl = "helm",
      gotmpl = "gotmpl",
      -- Nushell scripts
      nu = "nu",
    },
    filename = {
      -- Kustomize files
      ["kustomization.yaml"] = "yaml.kustomize",
      ["kustomization.yml"] = "yaml.kustomize",
      -- Nushell config
      ["config.nu"] = "nu",
      ["env.nu"] = "nu",
    },
    pattern = {
      -- Kubernetes manifests in k8s directories
      [".*/k8s/.*%.ya?ml"] = "yaml.kubernetes",
      -- Helm templates
      [".*/templates/.*%.ya?ml"] = "helm",
      [".*/templates/.*%.tpl"] = "helm",
    },
  })
end

return M
