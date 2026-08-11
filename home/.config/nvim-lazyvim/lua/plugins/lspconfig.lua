return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "gr", vim.lsp.buf.code_action },
          },
        },
        ahk2 = {
          autostart = true,
          cmd = {
            "node",
            vim.fn.expand("~/vscode-autohotkey2-lsp/server/dist/server.js"),
            "--stdio",
          },
          filetypes = { "ahk", "autohotkey", "ah2" },
          init_options = {
            locale = "en-us",
            InterpreterPath = "/mnt/c/Program\\ Files/AutoHotkey/v2/AutoHotkey.exe",
          },
          single_file_support = true,
          flags = { debounce_text_changes = 500 },
        },
        ts_ls = { enabled = false },
        tsserver = { enabled = false },
        tailwindcss = { enabled = false },
        -- lua_ls = { enabled = false },
        gopls = { maxMemory = 600, enabled = true, autostart = false },
        eslint = { enabled = false },
        vtsls = {
          -- enabled = false,
          autostart = false,
          settings = {
            typescript = {
              tsserver = {
                maxTsServerMemory = 500,
              },
            },
          },
        },
      },
    },
  },
  { "mfussenegger/nvim-lint", opts = { linters_by_ft = { go = {} } } },
}
