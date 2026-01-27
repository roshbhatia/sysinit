return {
  {
    "ramilito/kubectl.nvim",
    version = "2.*",
    dependencies = "saghen/blink.download",
    cmd = {
      "Kubectl",
      "Kubens",
      "Kubectx",
    },
    config = function()
      require("kubectl").setup()
    end,
  },
}
