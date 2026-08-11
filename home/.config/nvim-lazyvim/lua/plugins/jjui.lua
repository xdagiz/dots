return {
  {
    "xdagiz/jjui.nvim",
    lazy = true,
    cmd = { "Jjui", "JjuiToggle" },
    keys = {
      { "<leader>jj", "<cmd>Jjui<cr>", desc = "JJui" },
      { "<leader>jt", "<cmd>JjuiToggle<cr>", desc = "Toggle Jjui" },
    },
    config = function()
      require("jjui").setup({
        scaling = 0.9,
        border = "none",
        winblend = 0,
        on_exit = function(code)
          -- optional callback
        end,
      })
    end,
  },
}
