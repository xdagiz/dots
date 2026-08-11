return {
  "ThePrimeagen/99",
  config = function()
    local _99 = require("99")
    local cwd = vim.uv.cwd()
    local basename = vim.fs.basename(cwd)

    _99.setup({
      -- provider = _99.Providers.ClaudeCodeProvider,  -- default: OpenCodeProvider
      logger = {
        level = _99.DEBUG,
        path = "/tmp/" .. basename .. ".99.debug",
        print_on_error = true,
      },
      tmp_dir = "./tmp",
      completion = {
        files = {
          enabled = true,
          max_file_size = 102400, -- bytes, skip files larger than this
          -- max_files = 5000,            -- cap on total discovered files
          -- exclude = { ".env", ".env.*", "node_modules", ".git", ... },
        },
        source = "native", -- "native" (default), "cmp", or "blink"
      },
      md_files = {
        "AGENT.md",
      },
    })

    vim.keymap.set("v", "<leader>9v", function()
      _99.visual()
    end)

    vim.keymap.set("n", "<leader>9x", function()
      _99.stop_all_requests()
    end)

    vim.keymap.set("n", "<leader>9s", function()
      _99.search()
    end)
  end,
}
