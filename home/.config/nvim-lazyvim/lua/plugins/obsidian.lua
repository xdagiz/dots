return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    lazy = true,
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "personal",
          path = "~/Documents/Vault/",
        },
      },
      templates = {
        folder = "~/Documents/Vault/0 - Templates/",
      },
    },
  },
}
