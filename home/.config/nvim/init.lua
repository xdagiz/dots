vim.loader.enable()

require("config")
require("plugins")

vim.pack.add({
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/folke/lazydev.nvim" },
})

require("mason").setup()
vim.keymap.set("n", "<leader>cm", "<Cmd>Mason<CR>")

require("lazydev").setup({
	library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
})
