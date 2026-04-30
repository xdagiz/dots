local utils = require("utils")

vim.pack.add({
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/nvim-lualine/lualine.nvim" },
	{ src = "https://github.com/nvim-mini/mini.icons", version = "stable" },
	{ src = "https://github.com/akinsho/nvim-bufferline.lua" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
	{ src = "https://github.com/rcarriga/nvim-notify" },
	{ src = "https://github.com/MunifTanjim/nui.nvim" },
	{ src = "https://github.com/folke/noice.nvim" },
	{ src = "https://github.com/smjonas/inc-rename.nvim" },
	{ src = "https://github.com/folke/todo-comments.nvim" },
})

require("ibl").setup({
	indent = { char = "▏" },
	scope = {
		show_start = false,
		show_end = false,
	},
})

require("catppuccin").setup({
	auto_integrations = true,
	integrations = {
		blink_cmp = true,
		flash = true,
		grug_far = true,
		gitsigns = true,
		indent_blankline = {
			enabled = true,
		},
		lsp_trouble = true,
		mason = true,
		mini = true,
		navic = { enabled = true, custom_bg = "lualine" },
		noice = true,
		notify = true,
		snacks = true,
		telescope = true,
		treesitter_context = true,
	},
	lsp_styles = {
		underlines = {
			errors = { "undercurl" },
			hints = { "undercurl" },
			warnings = { "undercurl" },
			information = { "undercurl" },
		},
	},
	transparent_background = true,
	float = {
		solid = true,
		transparent = true,
	},
})
vim.cmd("colorscheme catppuccin-mocha")

require("notify").setup({
	timeout = 500,
	stages = "fade",
	on_open = function(win)
		vim.api.nvim_win_set_config(win, { focusable = false })
	end,
})

require("noice").setup({
	notify = {
		enabled = true,
		view = "notify",
	},
	cmdline = {
		view = "cmdline",
	},
	lsp = {
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true,
		},
	},
	routes = {
		{
			filter = {
				event = "msg_show",
				any = {
					{ find = "%d+L, %d+B" },
					{ find = "; after #%d+" },
					{ find = "; before #%d+" },
				},
			},
			view = "mini",
		},
	},
	presets = {
		bottom_search = true,
		command_palette = true,
		long_message_to_split = true,
		lsp_doc_border = true,
		inc_rename = true,
	},
})

package.preload["nvim-web-devicons"] = function()
	require("mini.icons").mock_nvim_web_devicons()
	return package.loaded["nvim-web-devicons"]
end
require("mini.icons").setup({
	file = {
		[".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
		["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
	},
	filetype = {
		dotenv = { glyph = "", hl = "MiniIconsYellow" },
	},
})

require("inc_rename").setup({})
vim.keymap.set("n", "<leader>rn", function()
	return ":IncRename " .. vim.fn.expand("<cword>")
end, { expr = true })

vim.keymap.set("n", "<leader>sn", "<cmd>Noice<cr>")
vim.keymap.set("n", "<leader>snl", "<cmd>NoiceLast<cr>")
vim.keymap.set("n", "<leader>sna", "<cmd>NoiceAll<cr>")
vim.keymap.set("n", "<leader>snd", "<cmd>NoiceDismiss<cr>")

require("gitsigns").setup({
	signs = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = "" },
		topdelete = { text = "" },
		changedelete = { text = "▎" },
		untracked = { text = "▎" },
	},
	signs_staged = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = "" },
		topdelete = { text = "" },
		changedelete = { text = "▎" },
	},
	on_attach = function(buffer)
		local gs = package.loaded.gitsigns

		local function map(mode, l, r, desc)
			vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
		end

		map("n", "]h", function()
			if vim.wo.diff then
				vim.cmd.normal({ "]c", bang = true })
			else
				gs.nav_hunk("next")
			end
		end, "Next Hunk")
		map("n", "[h", function()
			if vim.wo.diff then
				vim.cmd.normal({ "[c", bang = true })
			else
				gs.nav_hunk("prev")
			end
		end, "Prev Hunk")
		map("n", "]H", function()
			gs.nav_hunk("last")
		end, "Last Hunk")
		map("n", "[H", function()
			gs.nav_hunk("first")
		end, "First Hunk")
		map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
		map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
		map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
		map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
		map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
		map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
		map("n", "<leader>ghb", function()
			gs.blame_line({ full = true })
		end, "Blame Line")
		map("n", "<leader>ghB", function()
			gs.blame()
		end, "Blame Buffer")
		map("n", "<leader>ghd", gs.diffthis, "Diff This")
		map("n", "<leader>ghD", function()
			gs.diffthis("~")
		end, "Diff This ~")
		map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
	end,
})

require("lualine").setup({
	options = {
		theme = "auto",
		component_separators = "",
		section_separators = { left = "", right = "" },
		globalstatus = vim.o.laststatus == 3,
		disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch" },

		lualine_c = {
			{ "filename" },
			{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
			{
				function()
					local reg = vim.fn.reg_recording()
					if reg == "" then
						return ""
					end
					return "recording @" .. reg
				end,
				color = { fg = "#f9e2af" },
			},
		},
		lualine_x = {
			{
				"lsp_status",
			},
			{
				"diagnostics",
				symbols = {
					error = " ",
					warn = " ",
					info = " ",
					hint = " ",
				},
			},
			{
				"diff",
				symbols = { added = " ", modified = " ", removed = " " },
			},
		},
		lualine_y = {
			{ "progress", separator = " ", padding = { left = 1, right = 0 } },
			{ "location", padding = { left = 0, right = 1 } },
		},
		lualine_z = {
			function()
				return os.date("%I:%M %p")
			end,
		},
	},
})

require("bufferline").setup({
	options = {
		mode = "buffers",
		-- separator_style = "thin",
		show_buffer_close_icons = true,
		show_close_icon = true,
		close_command = function(n)
			utils.bufdelete(n)
		end,
		right_mouse_command = function(n)
			utils.bufdelete(n)
		end,
		always_show_bufferline = false,
	},
	highlights = require("catppuccin.special.bufferline").get_theme(),
})

require("todo-comments").setup({})

vim.keymap.set("n", "]t", function()
	require("todo-comments").jump_next()
end, { desc = "Next todo comment" })

vim.keymap.set("n", "[t", function()
	require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })

vim.keymap.set("n", "]t", function()
	require("todo-comments").jump_next({ keywords = { "ERROR", "WARNING" } })
end, { desc = "Next error/warning todo comment" })
