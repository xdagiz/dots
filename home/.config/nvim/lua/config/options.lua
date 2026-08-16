local o = vim.opt

vim.o.winborder = "rounded"

o.number = true
o.relativenumber = true
o.tabstop = 2
o.shiftwidth = 2
o.showtabline = 2
o.signcolumn = "yes"
o.wrap = false
o.cursorcolumn = false
o.smartindent = true
o.termguicolors = true
o.undofile = true
o.undolevels = 10000
o.updatetime = 200
o.guicursor = "n-v-c-sm:block,i-ci-ve:block,r-cr-o:hor20,a:blinkwait700-blinkoff400-blinkon250"
o.swapfile = false
o.autowrite = true
o.conceallevel = 2
o.confirm = true
o.cursorline = true
o.expandtab = true
o.fillchars = {
	foldopen = "",
	foldclose = "",
	fold = " ",
	foldsep = " ",
	diff = "╱",
	eob = " ",
}
o.foldlevel = 99
o.foldmethod = "indent"
o.foldtext = ""
o.grepprg = "rg --vimgrep"
o.ignorecase = true
o.inccommand = "nosplit"
o.jumpoptions = "view"
o.laststatus = 3
o.linebreak = true
o.pumblend = 10
o.pumheight = 10
o.ruler = false
o.scrolloff = 4
o.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
o.shortmess:append({ W = true, I = true, c = true, C = true })
o.sidescrolloff = 8
o.smartcase = true
o.smoothscroll = true
o.spelllang = { "en" }
o.splitbelow = true
o.splitkeep = "screen"
o.splitright = true
o.wildmode = "longest:full,full"
o.list = false
--
-- vim.o.autocomplete = true
--
-- vim.api.nvim_create_autocmd("LspAttach", {
-- 	group = vim.api.nvim_create_augroup("my.lsp", {}),
-- 	callback = function(ev)
-- 		local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
-- 		if client:supports_method("textDocument/completion") then
-- 			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
-- 		end
-- 	end,
-- })
--
-- vim.opt.complete:append("o")
-- vim.opt.completeopt = { "menu", "menuone", "noselect" }
-- vim.o.pumheight = 5
-- vim.o.pumborder = "rounded"
