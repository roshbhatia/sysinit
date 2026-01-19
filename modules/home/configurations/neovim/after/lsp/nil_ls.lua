return {
  settings = {
    ["nil"] = {
      nix = {
        -- Flake support
        flake = {
          autoArchive = false, -- Don't automatically archive flake inputs
          autoEvalInputs = true,
        },

        -- Binary cache
        binary = {
          evaluation = {
            workers = 4,
          },
        },

        -- Formatting
        formatting = {
          command = { "alejandra" }, -- Use alejandra formatter
        },
      },
    },
  },
}
