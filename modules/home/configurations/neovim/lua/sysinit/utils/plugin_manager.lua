local plugin_manager = {}

function plugin_manager.setup_package_manager()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  ---@diagnostic disable-next-line: undefined-field
  if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)
end

function plugin_manager.setup_plugins(modules)
  local specs = {}
  for _, M in ipairs(modules) do
    if M.plugins then
      for _, plugin in ipairs(M.plugins) do
        table.insert(specs, plugin)
      end
    end
  end

  require("lazy").setup({
    root = vim.fn.stdpath("data") .. "/lazy",
    lockfile = vim.fn.stdpath("data") .. "/lazy/lazy-lock.json",
    rocks = {
      enabled = true,
      root = vim.fn.stdpath("data") .. "/lazy-rocks",
    },
    spec = specs,
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip",
          "netrwPlugin",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
          "matchit",
          "matchparen",
          "shada_plugin",
        },
      },
      reset_packpath = true,
      reset_rtp = true,
    },
    change_detection = {
      notify = false,
      enabled = false, -- Disable for better performance
    },
    concurrency = 4, -- Optimize for modern systems
    dev = {
      path = vim.fn.stdpath("data") .. "/lazy-dev",
    },
    install = {
      colorscheme = {
        "catppuccin",
      },
    },
    ui = {
      border = "rounded",
    },
  })
end

return plugin_manager
