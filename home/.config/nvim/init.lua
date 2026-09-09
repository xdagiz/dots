vim.loader.enable()

require("config")
require("plugins")

vim.pack.add({
	{ src = "https://github.com/neovim/nvim-lspconfig" },
})

vim.pack.add({
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/folke/lazydev.nvim" },
}, {
	load = function() end,
})

vim.api.nvim_create_autocmd("CmdUndefined", {
	pattern = "Mason",
	once = true,
	callback = function()
		vim.cmd.packadd("mason.nvim")
		require("mason").setup()
	end,
})
vim.keymap.set("n", "<leader>cm", "<Cmd>Mason<CR>")

vim.api.nvim_create_autocmd("FileType", {
	pattern = "lua",
	once = true,
	callback = function()
		vim.cmd.packadd("lazydev.nvim")
		require("lazydev").setup({
			library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
		})
	end,
})
