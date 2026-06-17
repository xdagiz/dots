local opt = vim.opt

opt.guicursor = "n-v-c-sm:block,i-ci-ve:block,r-cr-o:hor20"
opt.swapfile = false
vim.g.ai_cmp = false
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
--vim.o.winborder = "rounded"

-- Rust
vim.g.rust_analyzer_lru_capacity = 32
vim.g.rust_analyzer_cache_priming_enable = 0
vim.g.rust_analyzer_check_command = "cargo check"
vim.g.lazyvim_rust_diagnostics = "bacon-ls"

vim.api.nvim_create_user_command("CloseAll", function()
  vim.cmd("bufdo bd")
end, { desc = "Close all buffers including current" })
