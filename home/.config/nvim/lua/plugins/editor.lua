vim.pack.add({
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim" },
	{ src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/L3MON4D3/LuaSnip" },
	{ src = "https://github.com/saghen/blink.cmp" },
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/nvim-mini/mini.ai" },
	{ src = "https://github.com/rafamadriz/friendly-snippets" },
	{
		src = "https://github.com/nvim-neo-tree/neo-tree.nvim",
		version = vim.version.range("3"),
	},
	{ src = "https://github.com/windwp/nvim-ts-autotag" },
	{ src = "https://github.com/folke/trouble.nvim" },
	{ src = "https://github.com/barrettruth/live-server.nvim" },
	{ src = "https://github.com/gbprod/yanky.nvim" },
	{ src = "https://github.com/nvim-mini/mini.move" },
	{ src = "https://github.com/nvim-mini/mini.surround" },
	{ src = "https://github.com/nvim-mini/mini.hipatterns" },
	{ src = "https://github.com/dmtrKovalenko/fff.nvim" },
	{ src = "https://github.com/xdagiz/jjui.nvim" },
	{ src = "https://github.com/MagicDuck/grug-far.nvim" },
	{ src = "https://github.com/NicolasGB/jj.nvim" },
	{ src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
	{ src = "https://github.com/folke/flash.nvim" },
	{ src = "https://github.com/folke/persistence.nvim" },
})

require("nvim-treesitter").setup()

vim.api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		local lang = vim.treesitter.language.get_lang(ev.match)
		if not lang then
			return
		end
		if vim.treesitter.language.add(lang) then
			vim.treesitter.start(ev.buf, lang)
		end
	end,
})

require("yanky").setup({
	system_clipboard = {
		sync_with_ring = false,
		clipboard_register = nil,
	},
	highlight = { timer = 150 },
})

local map = vim.keymap.set
map({ "n", "x" }, "y", "<Plug>(YankyYank)")
map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
map({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
map({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
map({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")

map("n", "<c-p>", "<Plug>(YankyPreviousEntry)")
map("n", "<c-n>", "<Plug>(YankyNextEntry)")
map({ "n", "v" }, "<leader>p", function()
	require("telescope").extensions.yank_history.yank_history({})
end)

require("luasnip").filetype_extend("javascriptreact", { "html" })
require("luasnip").filetype_extend("typescriptreact", { "html" })
require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_lua").load({ paths = vim.fn.stdpath("config") .. "/snippets" })
require("luasnip").setup({ enable_autosnippets = true, store_selection_keys = "<Tab>" })

require("grug-far").setup()

local ai = require("mini.ai")
require("mini.ai").setup({
	n_lines = 500,
	custom_textobjects = {
		o = ai.gen_spec.treesitter({ -- code block
			a = { "@block.outer", "@conditional.outer", "@loop.outer" },
			i = { "@block.inner", "@conditional.inner", "@loop.inner" },
		}),
		f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
		c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
		t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
		d = { "%f[%d]%d+" }, -- digits
		e = { -- Word with case
			{ "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
			"^().*()$",
		},
		u = ai.gen_spec.function_call(), -- u for "Usage"
		U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
	},
})

local telescope = require("telescope")
local actions = require("telescope.actions")
local builtin = require("telescope.builtin")

local find_files_no_ignore = function()
	local action_state = require("telescope.actions.state")

	local line = action_state.get_current_line()
	builtin.find_files({
		no_ignore = true,
		default_text = line,
	})
end

local find_files_with_hidden = function()
	local action_state = require("telescope.actions.state")

	local line = action_state.get_current_line()
	builtin.find_files({
		hidden = true,
		default_text = line,
	})
end

telescope.setup({
	defaults = {
		prompt_prefix = " ",
		selection_caret = " ",
		preview = { treesitter = true },
		color_devicons = true,
		path_displays = { "smart" },
		layout_config = {
			height = 30,
			width = 120,
			preview_cutoff = 40,
		},
		mappings = {
			i = {
				["<a-i>"] = find_files_no_ignore,
				["<a-h>"] = find_files_with_hidden,
				["<C-Down>"] = actions.cycle_history_next,
				["<C-Up>"] = actions.cycle_history_prev,
				["<C-f>"] = actions.preview_scrolling_down,
				["<C-b>"] = actions.preview_scrolling_up,
			},
			n = {
				["q"] = actions.close,
			},
		},
	},
	pickers = {
		find_files = {
			find_command = { "rg", "--files", "--color", "never", "-g", "!.git" },
			-- hidden = true,
			-- theme = "", -- dropdown, ivy, cursor
		},
	},
	extensions = {
		["ui-select"] = require("telescope.themes").get_dropdown({}),
	},
})
pcall(telescope.load_extension, "ui-select")

map({ "n" }, "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
map({ "n" }, "<leader>sg", builtin.live_grep, { desc = "Telescope live grep" })
map({ "n" }, "<leader>/", builtin.live_grep, { desc = "Telescope live grep" })
map({ "n" }, "<leader>fb", builtin.buffers, { desc = "Telescope find buffers" })
map({ "n" }, "<leader>fg", "<cmd>Telescope git_files<cr>", { desc = "Telescope find git files" })
map({ "n", "v" }, "<leader>sw", builtin.grep_string, { desc = "Telescope grep string" })
map({ "n" }, "<leader>so", builtin.oldfiles, { desc = "Telescope old files" })
map({ "n" }, "<leader>sh", builtin.help_tags, { desc = "Telescope help tags" })
map({ "n", "v" }, "<leader>gr", builtin.lsp_references, { desc = "Telescope lsp references" })
map({ "n" }, "<leader>sd", builtin.diagnostics, { desc = "Telescope diagnostics" })
map({ "n" }, "<leader>sT", builtin.lsp_type_definitions, { desc = "Telescope lsp type definitions" })
map({ "n" }, "<leader>sc", builtin.git_bcommits, { desc = "Telescope git commits" })
map({ "n" }, "<leader>sk", builtin.keymaps, { desc = "Telescope search keymaps" })
map({ "n" }, "<leader>sR", builtin.resume, { desc = "Telescope resume" })
map({ "n" }, "<esc>", "<cmd>nohlsearch<cr>", { noremap = true })
map({ "n" }, "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", { desc = "Toggle Pin" })
map({ "n" }, "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", { desc = "Delete Non-Pinned Buffers" })
map({ "n" }, "<leader>br", "<Cmd>BufferLineCloseRight<CR>", { desc = "Delete Buffers to the Right" })
map({ "n" }, "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", { desc = "Delete Buffers to the Left" })
map({ "n" }, "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
map({ "n" }, "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
map({ "n" }, "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
map({ "n" }, "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
map({ "n" }, "[B", "<cmd>BufferLineMovePrev<cr>", { desc = "Move buffer prev" })
map({ "n" }, "]B", "<cmd>BufferLineMoveNext<cr>", { desc = "Move buffer next" })

map({ "n", "x" }, "<leader>sr", "<cmd>GrugFar<cr>", { desc = "Grug far" })
map(
	{ "n" },
	"<leader>,",
	"<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
	{ desc = "Telescope find buffers" }
)
map({ "n" }, "<leader>:", "<cmd>Telescope command_history<cr>", { desc = "Telescope command history" })
map(
	{ "n" },
	"<leader>fb",
	"<cmd>Telescope buffers sort_mru=true sort_lastused=true ignore_current_buffer=true<cr>",
	{ desc = "Telescope find buffers" }
)
map({ "n" }, "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "Telescope git commits" })
map({ "n" }, "<leader>gl", "<cmd>Telescope git_commits<CR>", { desc = "Telescope git commits" })
map({ "n" }, "<leader>gs", "<cmd>Telescope git_status<CR>", { desc = "Telescope git status" })
map({ "n" }, "<leader>gS", "<cmd>Telescope git_stash<cr>", { desc = "Telescope git stash" })
map({ "n" }, "<leader>sr", "<cmd>Telescope registers<cr>", { desc = "Registers" })
map({ "n" }, "<leader>sa", "<cmd>Telescope autocommands<cr>", { desc = "Auto Commands" })
map({ "n" }, "<leader>sH", "<cmd>Telescope highlights<cr>", { desc = "Search Highlight Groups" })
map({ "n" }, "<leader>sj", "<cmd>Telescope jumplist<cr>", { desc = "Jumplist" })
map({ "n" }, "<leader>sl", "<cmd>Telescope loclist<cr>", { desc = "Location List" })
map({ "n" }, "<leader>sM", "<cmd>Telescope man_pages<cr>", { desc = "Man Pages" })
map({ "n" }, "<leader>sm", "<cmd>Telescope marks<cr>", { desc = "Jump to Mark" })
map({ "n" }, "<leader>sR", "<cmd>Telescope resume<cr>", { desc = "Resume" })
map({ "n" }, "<leader>sQ", "<cmd>Telescope quickfix<cr>", { desc = "Quickfix List" })
map({ "n" }, "<leader>ss", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "Goto Symbol" })

map({ "n" }, "<leader>fc", function()
	builtin.find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find nvim config files" })

map({ "n" }, "<leader>fd", function()
	builtin.git_files({ cwd = "~/dotfiles", show_untracked = true })
end, { desc = "Find dotfiles" })

---@module "blink.cmp.config"
require("blink.cmp").setup({
	snippets = {
		preset = "luasnip",
	},
	appearance = {
		use_nvim_cmp_as_default = false,
		nerd_font_variant = "mono",
	},
	completion = {
		accept = {
			auto_brackets = {
				enabled = true,
			},
		},
		menu = {
			draw = {
				treesitter = { "lsp" },
				columns = {
					{ "label", "label_description" },
					{ "kind_icon", gap = 1 },
					{ "kind" },
				},
			},
			auto_show = true,
			border = "rounded",
			winhighlight = "Normal:None",
			max_height = 20,
			min_width = 16,
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 200,
		},
	},
	sources = {
		per_filetype = {
			lua = { inherit_defaults = true, "lazydev" },
		},
		providers = {
			lazydev = {
				name = "LazyDev",
				module = "lazydev.integrations.blink",
				score_offset = 100,
			},
			snippets = {
				name = "snippets",
				module = "blink.cmp.sources.snippets",
			},
		},
		default = { "lsp", "path", "snippets", "buffer" },
	},
	fuzzy = {
		implementation = "lua",
	},
	cmdline = {
		enabled = true,
		keymap = {
			preset = "cmdline",
			["<Right>"] = false,
			["<Left>"] = false,
		},
		completion = {
			list = { selection = { preselect = false, auto_insert = true } },
			menu = {
				auto_show = function(_)
					return vim.fn.getcmdtype() == ":"
				end,
			},
			ghost_text = { enabled = true },
		},
	},
	keymap = {
		preset = "super-tab",
		["<C-y>"] = { "select_and_accept" },
	},
})

local function has_root_file(bufnr, names)
	local path = vim.api.nvim_buf_get_name(bufnr)
	local start = path ~= "" and vim.fs.dirname(path) or vim.uv.cwd()
	return vim.fs.find(names, { path = start, upward = true })[1] ~= nil
end

local function js_formatter_for(bufnr)
	if has_root_file(bufnr, { "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" }) then
		return { "biome" }
	end

	if has_root_file(bufnr, { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmtrc.json", "oxfmtrc.jsonc" }) then
		return { "oxfmt" }
	end

	if
		has_root_file(bufnr, {
			".prettierrc",
			".prettierrc.json",
			".prettierrc.yml",
			".prettierrc.yaml",
			".prettierrc.json5",
			".prettierrc.js",
			".prettierrc.cjs",
			".prettierrc.mjs",
			".prettierrc.ts",
			".prettierrc.cts",
			".prettierrc.mts",
			".prettierrc.toml",
			"prettier.config.js",
			"prettier.config.cjs",
			"prettier.config.mjs",
			"prettier.config.ts",
			"prettier.config.cts",
			"prettier.config.mts",
		})
	then
		return { "prettier" }
	end

	return { "oxfmt" }
end

require("conform").setup({
	format_on_save = function(bufnr)
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		return { timeout_ms = 5000, lsp_fallback = true }
	end,
	default_format_opts = { stop_after_first = true, timeout_ms = 1000, lsp_fallback = true },
	formatters_by_ft = {
		lua = { "stylua" },
		html = { "oxfmt" },
		-- css = { "oxfmt" },
		json = { "oxfmt", "biome", "prettier" },
		jsonc = { "prettier" },
		css = js_formatter_for,
		javascript = js_formatter_for,
		typescript = js_formatter_for,
		javascriptreact = js_formatter_for,
		typescriptreact = js_formatter_for,
		nix = { "nixfmt" },
		toml = { "taplo" },
		rust = { "rustfmt", lsp_format = "fallback" },
		-- markdown = { "prettier" },
		go = { "goimports", "gofumpt" },
		-- kdl = { "kdlfmt" },
		yaml = { "oxfmt" },
	},
})

vim.api.nvim_create_user_command("FormatDisable", function()
	vim.g.disable_autoformat = true
end, { desc = "Disable autoformat-on-save globally" })

vim.api.nvim_create_user_command("BufFormatDisable", function()
	vim.b.disable_autoformat = true
end, { desc = "Disable autoformat-on-save for current buffer" })

vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end, { desc = "Re-enable autoformat-on-save" })

require("nvim-ts-autotag").setup({
	opts = {
		enable_close = true,
		enable_rename = true,
		enable_close_on_slash = false,
	},
})

require("oil").setup({
	lsp_file_methods = {
		enabled = true,
		timeout_ms = 1000,
		autosave_changes = true,
	},
	columns = {
		"icon",
	},
	float = {
		max_width = 0.5,
		max_height = 0.6,
		border = "rounded",
	},
	-- Buffer-local options to use for oil buffers
	buf_options = {
		buflisted = true,
		bufhidden = "hide",
	},
	delete_to_trash = false,
	skip_confirm_for_simple_edits = false,
	prompt_save_on_select_new_entry = true,
	-- Constrain the cursor to the editable parts of the oil buffer
	-- Set to `false` to disable, or "name" to keep it on the file names
	constrain_cursor = "editable",
	-- Set to true to watch the filesystem for changes and reload oil
	watch_for_changes = false,
	view_options = {
		show_hidden = true,
	},
})

require("neo-tree").setup({
	default_component_configs = {
		git_status = {
			symbols = {
				added = "",
				modified = "",
				deleted = "",
				renamed = "",
				ignored = "",
				untracked = "",
				unstaged = "",
				staged = "",
				conflict = "",
			},
		},
	},
	filesystem = {
		use_libuv_file_watcher = true,
		follow_current_file = {
			enabled = true,
			leave_dirs_open = true,
		},
		reveal_force_cwd = true,
	},
	window = {
		width = 30,
		mappings = {
			["/"] = "noop",
			["l"] = {
				"open",
			},
			["h"] = {
				"close_node",
			},
		},
	},
})

require("trouble").setup({
	modes = {
		lsp = {
			win = { position = "right" },
		},
	},
})

map({ "n", "v" }, "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map(
	{ "n", "v" },
	"<leader>xX",
	"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
	{ desc = "Buffer Diagnostics (Trouble)" }
)
map({ "n", "v" }, "<leader>cs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols (Trouble)" })
map({ "n", "v" }, "<leader>cS", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP references/definitions/... (Trouble)" })
map({ "n", "v" }, "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
map({ "n", "v" }, "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
map({ "n", "v" }, "[q", function()
	if require("trouble").is_open() then
		require("trouble").prev({ skip_groups = true, jump = true })
	else
		local ok, err = pcall(vim.cmd.cprev)
		if not ok then
			vim.notify(err, vim.log.levels.ERROR)
		end
	end
end, { desc = "Prev quickfix item" })

map({ "n", "v" }, "]q", function()
	if require("trouble").is_open() then
		require("trouble").next({ skip_groups = true, jump = true })
	else
		local ok, err = pcall(vim.cmd.cnext)
		if not ok then
			vim.notify(err, vim.log.levels.ERROR)
		end
	end
end, { desc = "Next quickfix item" })

require("mini.move").setup({})
require("mini.surround").setup({
	-- mappings = {
	-- 	add = "gza",
	-- 	delete = "gzd",
	-- 	find = "gzf",
	-- 	find_left = "gzF",
	-- 	highlight = "gzh",
	-- 	replace = "gzr",
	-- 	update_n_lines = "gzn",
	-- },
	custom_surroundings = {
		["("] = { output = { left = "(", right = ")" } },
		["["] = { output = { left = "[", right = "]" } },
		["{"] = { output = { left = "{", right = "}" } },
		["<"] = { output = { left = "<", right = ">" } },
	},
})

local hipatterns = require("mini.hipatterns")
hipatterns.setup({
	tailwind = {
		enabled = true,
		ft = {
			"astro",
			"css",
			"heex",
			"html",
			"html-eex",
			"javascript",
			"javascriptreact",
			"rust",
			"svelte",
			"typescript",
			"typescriptreact",
			"vue",
		},
		style = "full",
	},
	highlighters = {
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
		hex_color = hipatterns.gen_highlighter.hex_color(),
	},
})

vim.g.fff = {
	lazy_sync = true,
	debug = { enabled = true, show_scores = true },
}

require("fff").setup({
	base_path = vim.fn.getcwd(),
	prompt = " ",
	title = "Files",
	layout = {
		height = 0.6,
		width = 0.8,
	},
})

local fff = require("fff")
map({ "n" }, "<leader>ff", function()
	fff.find_files()
end, { desc = "Find files" })

map({ "n" }, "<leader>so", function()
	fff.find_files({ frecency = true })
end, { desc = "Old/frecent files" })

map({ "n" }, "<leader>sg", function()
	fff.live_grep()
end, { desc = "Live grep" })

map({ "n" }, "<leader>/", function()
	fff.live_grep()
end, { desc = "Live grep" })

local jjui = require("jjui")
jjui.setup({
	scaling = { width = 0.4, height = 0.8 },
	border = "rounded",
	winblend = 0,
})

require("jj").setup({})

vim.keymap.set("n", "<leader>jj", jjui.open, { desc = "Open jjui" })
vim.keymap.set("n", "<leader>jt", jjui.toggle, { desc = "Toggle jjui" })

local harpoon = require("harpoon")
harpoon:setup({})

vim.keymap.set("n", "<leader>H", function()
	harpoon:list():add()
end, { desc = "Harpoon: Add file" })

vim.keymap.set("n", "<leader>h", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon: Menu" })

for i = 1, 5 do
	vim.keymap.set("n", "<leader>" .. i, function()
		harpoon:list():select(i)
	end, { desc = "Harpoon: File " .. i })
end

local flash = require("flash")
flash.setup({})

vim.keymap.set({ "n", "x", "o" }, "ss", function()
	flash.jump()
end)

vim.keymap.set({ "n", "x", "o" }, "S", function()
	flash.treesitter()
end)

local persistence = require("persistence")
vim.keymap.set("n", "<leader>qs", function()
	persistence.load()
end)
vim.keymap.set("n", "<leader>qS", function()
	persistence.select()
end)
vim.keymap.set("n", "<leader>ql", function()
	persistence.load({ last = true })
end)
vim.keymap.set("n", "<leader>qd", function()
	persistence.stop()
end)
