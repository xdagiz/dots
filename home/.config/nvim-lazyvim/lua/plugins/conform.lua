return {
  "stevearc/conform.nvim",
  event = "VeryLazy",
  ---@type conform.setupOpts
  opts = {
    default_format_opts = { stop_after_first = true, timeout_ms = 1000 },
    formatters_by_ft = {
      javascript = { "oxfmt" },
      typescript = { "oxfmt" },
      javascriptreact = { "oxfmt" },
      typescriptreact = { "biome", "oxfmt" },
      -- markdown = { "prettier" },
      go = { "goimports", "gofumpt" },
    },
  },
}
