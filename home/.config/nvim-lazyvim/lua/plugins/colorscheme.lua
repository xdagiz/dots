return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    ---@module 'catppuccin'
    ---@type CatppuccinOptions
    opts = {
      transparent_background = true,
      float = {
        solid = true,
        transparent = true,
      },
    },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = {
      variant = "moon",
      styles = {
        transparency = true,
        italic = false,
      },
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = { transparent = true, styles = { floats = "transparent", sidebars = "transparent" } },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
  {
    "nexxeln/vesper.nvim",
    lazy = true,
    opts = {
      transparent = true,
    },
  },
}
