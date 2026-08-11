return {
  "saghen/blink.cmp",
  opts_extend = {
    "sources.completion.enabled_providers",
    "sources.compat",
    "sources.default",
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    completion = {
      accept = {
        auto_brackets = {
          enabled = true,
        },
      },
      menu = {
        draw = { treesitter = { "lsp" } },
        auto_show = true,
        border = "rounded",
        winhighlight = "Normal:None",
        max_height = 20,
        min_width = 16,
      },
    },

    keymap = {
      preset = "super-tab",
      ["<C-y>"] = { "select_and_accept" },
    },
  },
}
