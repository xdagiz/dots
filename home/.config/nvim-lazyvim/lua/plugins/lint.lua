return {
  "mfussenegger/nvim-lint",
  opts = {
    -- Specify linters for filetypes
    linters_by_ft = {
      javascript = { "oxlint" },
      typescript = { "oxlint" },
      typescriptreact = { "oxlint" },
      javascriptreact = { "oxlint" },
      -- Add other filetypes as needed
    },
    -- Configure linter to run on save
    events = { "BufWritePost", "BufReadPost", "InsertLeave" },
  },
  config = function(_, opts)
    local lint = require("lint")
    lint.linters_by_ft = opts.linters_by_ft

    -- Create autocmd for linting on save
    vim.api.nvim_create_autocmd(opts.events, {
      callback = function()
        require("lint").try_lint()
      end,
    })
  end,
}
