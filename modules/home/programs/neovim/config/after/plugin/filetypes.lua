vim.filetype.add({
  extension = {
    h = "c",
    tmpl = "helm",
    gotmpl = "gotmpl",
    nu = "nu",
  },
  filename = {
    ["kustomization.yaml"] = "yaml.kustomize",
    ["kustomization.yml"] = "yaml.kustomize",
    ["config.nu"] = "nu",
    ["env.nu"] = "nu",
  },
  pattern = {
    [".*/k8s/.*%.ya?ml"] = "yaml.kubernetes",
    [".*/templates/.*%.ya?ml"] = "helm",
    [".*/templates/.*%.tpl"] = "helm",
  },
})
