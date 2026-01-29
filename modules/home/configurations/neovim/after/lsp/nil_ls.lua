return {
  settings = {
    ["nil"] = {
      nix = {
        flake = {
          autoArchive = false,
          autoEvalInputs = true,
        },
        evaluation = {
          workers = 4,
        },
        formatting = {
          command = { "alejandra" },
        },
      },
    },
  },
}
