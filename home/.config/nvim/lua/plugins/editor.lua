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
	{ src = "https://github.com/pablopunk/pi.nvim" },
})

local telescope_loaded = false
local telescope, actions, builtin
local telescope_setup_fn

local function ensure_telescope()
	if telescope_loaded then
		return true
	end
	telescope_loaded = true

	local ok, err = pcall(function()
		pcall(vim.api.nvim_del_user_command, "Telescope")
		vim.g.loaded_telescope = nil
		vim.cmd.packadd("telescope.nvim")
		telescope = require("telescope")
		actions = require("telescope.actions")
		builtin = require("telescope.builtin")
		telescope_setup_fn()
	end)
	if not ok then
		telescope_loaded = false
		vim.notify("telescope failed to load: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end

	return true
end

local function telescope_run(fn)
	return function(...)
		if ensure_telescope() then
			return fn(...)
		end
	end
end

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		pcall(vim.api.nvim_del_user_command, "Telescope")
		vim.api.nvim_create_user_command("Telescope", function(opts)
			if ensure_telescope() then
				vim.api.nvim_cmd({ cmd = "Telescope", args = opts.fargs }, {})
			end
		end, { nargs = "*" })
	end,
})

vim.api.nvim_create_autocmd("CmdUndefined", {
	pattern = "Telescope",
	callback = function()
		ensure_telescope()
	end,
})

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
map(
	{ "n", "v" },
	"<leader>p",
	telescope_run(function()
		require("telescope").extensions.yank_history.yank_history({})
	end)
)

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

telescope_setup_fn = function()
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
end

map({ "n" }, "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Telescope find files" })
map({ "n" }, "<leader>sg", "<cmd>Telescope live_grep<cr>", { desc = "Telescope live grep" })
map({ "n" }, "<leader>/", "<cmd>Telescope live_grep<cr>", { desc = "Telescope live grep" })
map({ "n" }, "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Telescope find buffers" })
map({ "n" }, "<leader>fg", "<cmd>Telescope git_files<cr>", { desc = "Telescope find git files" })
map({ "n", "v" }, "<leader>sw", "<cmd>Telescope grep_string<cr>", { desc = "Telescope grep string" })
map({ "n" }, "<leader>so", "<cmd>Telescope oldfiles<cr>", { desc = "Telescope old files" })
map({ "n" }, "<leader>sh", "<cmd>Telescope help_tags<cr>", { desc = "Telescope help tags" })
map({ "n", "v" }, "<leader>gr", "<cmd>Telescope lsp_references<cr>", { desc = "Telescope lsp references" })
map({ "n" }, "<leader>sd", "<cmd>Telescope diagnostics<cr>", { desc = "Telescope diagnostics" })
map({ "n" }, "<leader>sT", "<cmd>Telescope lsp_type_definitions<cr>", { desc = "Telescope lsp type definitions" })
map({ "n" }, "<leader>sc", "<cmd>Telescope git_bcommits<cr>", { desc = "Telescope git commits" })
map({ "n" }, "<leader>sk", "<cmd>Telescope keymaps<cr>", { desc = "Telescope search keymaps" })
map({ "n" }, "<leader>sR", "<cmd>Telescope resume<cr>", { desc = "Telescope resume" })
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
map({ "n" }, "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "Telescope git commits" })
map({ "n" }, "<leader>gs", "<cmd>Telescope git_status<CR>", { desc = "Telescope git status" })
map({ "n" }, "<leader>gS", "<cmd>Telescope git_stash<cr>", { desc = "Telescope git stash" })
map({ "n" }, "<leader>sr", "<cmd>Telescope registers<cr>", { desc = "Registers" })
map({ "n" }, "<leader>sa", "<cmd>Telescope autocommands<cr>", { desc = "Auto Commands" })
map({ "n" }, "<leader>sH", "<cmd>Telescope highlights<cr>", { desc = "Search Highlight Groups" })
map({ "n" }, "<leader>sj", "<cmd>Telescope jumplist<cr>", { desc = "Jumplist" })
map({ "n" }, "<leader>sl", "<cmd>Telescope loclist<cr>", { desc = "Location List" })
map({ "n" }, "<leader>sM", "<cmd>Telescope man_pages<cr>", { desc = "Man Pages" })
map({ "n" }, "<leader>sm", "<cmd>Telescope marks<cr>", { desc = "Jump to Mark" })
map({ "n" }, "<leader>sQ", "<cmd>Telescope quickfix<cr>", { desc = "Quickfix List" })
map({ "n" }, "<leader>ss", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "Goto Symbol" })

map(
	{ "n" },
	"<leader>fc",
	telescope_run(function()
		builtin.find_files({ cwd = vim.fn.stdpath("config") })
	end),
	{ desc = "Find nvim config files" }
)

map(
	{ "n" },
	"<leader>fd",
	telescope_run(function()
		builtin.git_files({ cwd = "~/dotfiles", show_untracked = true })
	end),
	{ desc = "Find dotfiles" }
)

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
		implementation = "prefer_rust_with_warning",
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

require("conform").setup({
	format_on_save = function(bufnr)
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		return { timeout_ms = 5000, lsp_format = "fallback" }
	end,
	default_format_opts = { stop_after_first = true, timeout_ms = 1000, lsp_format = "fallback" },
	formatters_by_ft = {
		lua = { "stylua" },
		html = { "oxfmt", "prettier", stop_after_first = true },
		css = { "oxfmt", "prettier", stop_after_first = true },
		json = { "oxfmt", "biome", "prettier", stop_after_first = true },
		jsonc = { "oxfmt", "prettier", stop_after_first = true },
		javascript = { "oxfmt", "biome", "prettier", stop_after_first = true },
		typescript = { "oxfmt", "biome", "prettier", stop_after_first = true },
		javascriptreact = { "oxfmt", "biome", "prettier", stop_after_first = true },
		typescriptreact = { "oxfmt", "biome", "prettier", stop_after_first = true },
		nix = { "nixfmt" },
		toml = { "taplo" },
		rust = { "rustfmt", lsp_format = "fallback" },
		-- markdown = { "prettier" },
		go = { "goimports", "gofumpt" },
		-- kdl = { "kdlfmt" },
		yaml = { "yamlfmt", "oxfmt", "prettier", stop_after_first = true },
	},
	formatters = {
		biome = { require_cwd = true },
		oxfmt = { require_cwd = false },
		prettier = { require_cwd = true },
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

local autotag_loaded = false
local autotag_fts = {
	"html",
	"xml",
	"heex",
	"typescriptreact",
	"glimmer",
	"typescript.glimmer",
	"svelte",
	"templ",
	"rust",
	"astro",
	"dot",
	"eruby",
	"liquid",
	"vue",
	"vento",
	"htmlangular",
	"htmldjango",
	"markdown",
	"php",
	"twig",
	"blade",
	"elixir",
	"javascriptreact",
	"javascript.jsx",
	"typescript.tsx",
	"javascript",
	"typescript",
	"rescript",
	"handlebars",
	"javascript.glimmer",
	"hbs",
}
vim.api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		if autotag_loaded then
			return
		end
		if not vim.tbl_contains(autotag_fts, vim.bo[ev.buf].filetype) then
			return
		end
		autotag_loaded = true
		require("nvim-ts-autotag").setup({
			opts = {
				enable_close = true,
				enable_rename = true,
				enable_close_on_slash = false,
			},
		})
		pcall(require("nvim-ts-autotag.internal").attach, ev.buf)
	end,
})

local oil_loaded = false
local function ensure_oil()
	if oil_loaded then
		return true
	end
	oil_loaded = true
	local ok, err = pcall(function()
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
	end)
	if not ok then
		oil_loaded = false
		vim.notify("oil failed to load: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end
	return true
end

vim.api.nvim_create_autocmd("CmdUndefined", {
	pattern = "Oil",
	callback = function()
		ensure_oil()
	end,
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

local trouble_loaded = false
local function ensure_trouble()
	if trouble_loaded then
		return true
	end
	trouble_loaded = true
	local ok, err = pcall(function()
		require("trouble").setup({
			modes = {
				lsp = {
					win = { position = "right" },
				},
			},
		})
	end)
	if not ok then
		trouble_loaded = false
		vim.notify("trouble failed to load: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end
	return true
end

vim.api.nvim_create_autocmd("CmdUndefined", {
	pattern = "Trouble",
	callback = function()
		ensure_trouble()
	end,
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
	if ensure_trouble() and require("trouble").is_open() then
		require("trouble").prev({ skip_groups = true, jump = true })
	else
		local ok, err = pcall(vim.cmd.cprev)
		if not ok then
			vim.notify(err, vim.log.levels.ERROR)
		end
	end
end, { desc = "Prev quickfix item" })

map({ "n", "v" }, "]q", function()
	if ensure_trouble() and require("trouble").is_open() then
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

require("fff").setup({
	base_path = vim.fn.getcwd(),
	prompt = " ",
	title = "Files",
	layout = {
		height = 0.6,
		width = 0.8,
	},
	grep = {
		modes = { "fuzzy", "regex", "plain" },
	},
	lazy_sync = true,
	debug = { enabled = true, show_scores = true },
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

local jj_loaded = false
local function ensure_jj()
	if jj_loaded then
		return true
	end
	jj_loaded = true
	local ok, err = pcall(function()
		require("jj").setup({})
	end)
	if not ok then
		jj_loaded = false
		vim.notify("jj failed to load: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end
	return true
end

vim.api.nvim_create_autocmd("CmdUndefined", {
	pattern = { "J", "Jbrowse", "Jread", "Jedit", "Jtabedit", "Jsplit", "Jvsplit", "Jdiff", "Jhdiff", "Jvdiff" },
	callback = function()
		ensure_jj()
	end,
})

local jjui = require("jjui")
jjui.setup({
	scaling = { width = 0.4, height = 0.8 },
	border = "rounded",
	winblend = 0,
})

vim.keymap.set("n", "<leader>jj", jjui.open, { desc = "Open jjui" })
vim.keymap.set("n", "<leader>jt", jjui.toggle, { desc = "Toggle jjui" })

local harpoon_loaded = false
local harpoon
local function ensure_harpoon()
	if harpoon_loaded then
		return true
	end
	harpoon_loaded = true
	local ok, err = pcall(function()
		harpoon = require("harpoon")
		harpoon:setup({})
	end)
	if not ok then
		harpoon_loaded = false
		vim.notify("harpoon failed to load: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end
	return true
end

vim.keymap.set("n", "<leader>H", function()
	if ensure_harpoon() then
		harpoon:list():add()
	end
end, { desc = "Harpoon: Add file" })

vim.keymap.set("n", "<leader>h", function()
	if ensure_harpoon() then
		harpoon.ui:toggle_quick_menu(harpoon:list())
	end
end, { desc = "Harpoon: Menu" })

for i = 1, 5 do
	vim.keymap.set("n", "<leader>" .. i, function()
		if ensure_harpoon() then
			harpoon:list():select(i)
		end
	end, { desc = "Harpoon: File " .. i })
end

require("pi").setup({})
