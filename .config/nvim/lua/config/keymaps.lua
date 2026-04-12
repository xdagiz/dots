local utils = require("utils")

local map = vim.keymap.set

vim.g.mapleader = " "
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bd", function()
	utils.bufdelete()
end)
map("n", "<leader>bo", function()
	utils.bufdelete_other()
end)

map("x", "<", "<gv")
map("x", ">", ">gv")

map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

map("n", "<leader>xq", function()
	local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
	if not success and err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Quickfix List" })

local diagnostic_goto = function(next, severity)
	return function()
		vim.diagnostic.jump({
			count = (next and 1 or -1) * vim.v.count1,
			severity = severity and vim.diagnostic.severity[severity] or nil,
			on_jump = function()
				vim.diagnostic.open_float()
			end,
		})
	end
end

map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })
map("n", "]i", diagnostic_goto(true, "INFO"), { desc = "Next Info" })
map("n", "[i", diagnostic_goto(false, "INFO"), { desc = "Prev Info" })

map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

map({ "n", "x" }, "<leader>y", '"+y')
map({ "n", "x" }, "<leader>d", '"+d')
map("x", "<leader>P", '"_dP', { noremap = true, desc = "Safe paste (black-hole)" })
map({ "n", "t" }, "<leader>t", "<Cmd>tabnew<CR>")
map({ "n", "x" }, "<S-h>", "<cmd>tabprev<CR>")
map({ "n", "x" }, "<S-l>", "<cmd>tabnext<CR>")
map("n", "<leader>w", "<cmd>write<cr>")
-- map({ "n", "x" }, "<leader>bd", "<cmd>tabclose<CR>")
-- for i = 1, 8 do
-- 	map({ "n", "t" }, "<leader>" .. i, "<Cmd>tabnext " .. i .. "<CR>")
-- end

map({ "n", "v", "x" }, "<leader>no", ":norm ", { desc = "ENTER NORM COMMAND." })
map({ "n", "v", "x" }, "<leader>nh", "<Cmd>nohlsearch<CR>")
map({ "n", "v", "x" }, "<leader>cf", vim.lsp.buf.format, { desc = "Format current buffer" })
map({ "v", "x", "n" }, "<C-y>", '"+y', { desc = "System clipboard yank." })
map({ "i" }, "<Tab>", "<C-x><C-o>")
map({ "n" }, "<M-n>", "<cmd>resize +2<CR>")
map({ "n" }, "<M-e>", "<cmd>resize -2<CR>")
map({ "n" }, "<M-i>", "<cmd>vertical resize +5<CR>")
map({ "n" }, "<M-m>", "<cmd>vertical resize -5<CR>")
map({ "n" }, "<leader>e", "<cmd>Neotree position=left toggle<CR>")
map({ "n" }, "<leader>o", "<cmd>Neotree position=float toggle<CR>")
map({ "n" }, "<leader>qq", "<Cmd>:quit<CR>", { desc = "Quit the current buffer." })
map({ "n" }, "<leader>wq", "<Cmd>:wqa<CR>", { desc = "Quit all buffers and write." })

map("n", "<leader>uw", function()
	vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle wrap" })

map("x", "<leader>P", '"_dP', { noremap = true, desc = "Safe paste (black-hole)" })
map("x", "<C-p>", '"_dP', { noremap = true, desc = "Safe paste (black-hole)" })
map("n", "<S-j>", "gJ", { noremap = true })

map({ "n", "i", "v" }, "<C-a>", "ggVG", { noremap = true })
-- map("i", "<C-Space>", "<C-X><C-O>")
map("n", "<leader>le", ":lsp enable ")
map("n", "<leader>ld", ":lsp disable ")
map("n", "<leader>ls", ":lsp stop ")
map("n", "<leader>lr", ":lsp restart ")
map("n", "<leader>uh", function()
	local is_enabled = vim.lsp.inlay_hint.is_enabled()
	if is_enabled then
		vim.lsp.inlay_hint.enable(false)
	else
		vim.lsp.inlay_hint.enable(true)
	end
end, { desc = "Toggle Inlay Hints" })

map("t", "<esc><esc>", "<c-\\><c-n>")
map("n", "<C-_>", ":botright 15split | term fish<CR>i")
