return {
  {
    "mrcjkb/rustaceanvim",
    ft = { "rust" },
    opts = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = false,
              loadOutDirsFromCheck = false,
              buildScripts = { enable = false },
              runBuildScripts = false,
            },
            checkOnSave = false,
            diagnostics = { enable = false },
            procMacro = { enable = false },
            files = {
              exclude = {
                ".direnv",
                ".git",
                ".jj",
                ".github",
                ".gitlab",
                "bin",
                "node_modules",
                "target",
                "venv",
                ".venv",
              },
              watcher = "client",
            },
            -- Disable dependent crate analysis
            linkedProjects = {},
          },
        },
      },
    },
  },
}
