return {
  {
    "folke/zen-mode.nvim",
    ---@module 'zen-mode'
    ---@type ZenOptions
    opts = {
      plugins = {
        options = {
          enabled = true,
          laststatus = 0,
        },
        twilight = { enabled = false },
        tmux = {
          enabled = false,
        },
      },
    },
  },
  {
    "folke/twilight.nvim",
    ---@module 'twilight'
    ---@type TwilightOptions
    opts = {
      dimming = {
        alpha = 0.40,
        color = { "Normal", "#ffffff" },
      },
    },
  },
}
