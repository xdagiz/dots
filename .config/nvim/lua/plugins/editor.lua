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

require("luasnip").filetype_extend("javascriptreact", { "html" })
require("luasnip").filetype_extend("typescriptreact", { "html" })
require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/snippets" })
require("luasnip").setup({ enable_autosnippets = true, store_selection_keys = "<Tab>" })

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

local map = vim.keymap.set
map({ "n" }, "<leader>ff", builtin.find_files, { desc = "Telescope live grep" })
map({ "n" }, "<leader>sg", builtin.live_grep)
map({ "n" }, "<leader>/", builtin.live_grep)
map({ "n" }, "<leader>fb", builtin.buffers)
map({ "n" }, "<leader>fg", "<cmd>Telescope git_files<cr>")
map({ "n", "v" }, "<leader>sw", builtin.grep_string)
map({ "n" }, "<leader>so", builtin.oldfiles)
map({ "n" }, "<leader>sh", builtin.help_tags)
map({ "n" }, "<leader>gr", builtin.lsp_references)
map({ "n" }, "<leader>sd", builtin.diagnostics)
map({ "n" }, "<leader>sT", builtin.lsp_type_definitions)
map({ "n" }, "<leader>sc", builtin.git_bcommits)
map({ "n" }, "<leader>sk", builtin.keymaps)
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
map({ "n", "x" }, "<leader>sr", "<cmd>GrugFar<cr>")
map({ "n" }, "<leader>,", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>")
map({ "n" }, "<leader>:", "<cmd>Telescope command_history<cr>")
map({ "n" }, "<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true ignore_current_buffer=true<cr>")
map({ "n" }, "<leader>gc", "<cmd>Telescope git_commits<CR>")
map({ "n" }, "<leader>gl", "<cmd>Telescope git_commits<CR>")
map({ "n" }, "<leader>gs", "<cmd>Telescope git_status<CR>")
map({ "n" }, "<leader>gS", "<cmd>Telescope git_stash<cr>")
map({ "n" }, "<leader>sr", "<cmd>Telescope registers<cr>", { desc = "Registers" })
map({ "n" }, "<leader>sa", "<cmd>Telescope autocommands<cr>", { desc = "Auto Commands" })
map({ "n" }, "<leader>sH", "<cmd>Telescope highlights<cr>", { desc = "Search Highlight Groups" })
map({ "n" }, "<leader>sj", "<cmd>Telescope jumplist<cr>", { desc = "Jumplist" })
map({ "n" }, "<leader>sl", "<cmd>Telescope loclist<cr>", { desc = "Location List" })
map({ "n" }, "<leader>sM", "<cmd>Telescope man_pages<cr>", { desc = "Man Pages" })
map({ "n" }, "<leader>sm", "<cmd>Telescope marks<cr>", { desc = "Jump to Mark" })
map({ "n" }, "<leader>sR", "<cmd>Telescope resume<cr>", { desc = "Resume" })
map({ "n" }, "<leader>sQ", "<cmd>Telescope quickfix<cr>", { desc = "Quickfix List" })

require("blink.cmp").setup({
	snippets = {
		preset = "default",
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
			draw = { treesitter = { "lsp" } },
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
			list = { selection = { preselect = false } },
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
	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = true,
	},
	default_format_opts = { stop_after_first = true, timeout_ms = 1000 },
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = js_formatter_for,
		typescript = js_formatter_for,
		javascriptreact = js_formatter_for,
		typescriptreact = js_formatter_for,
		-- markdown = { "prettier" },
		go = { "goimports", "gofumpt" },
		-- kdl = { "kdlfmt" },
	},
})

require("nvim-ts-autotag").setup({
	opts = {
		enable_close = true,
		enable_rename = true,
		enable_close_on_slash = false,
	},
})

-- require("oil").setup({
-- 	lsp_file_methods = {
-- 		enabled = true,
-- 		timeout_ms = 1000,
-- 		autosave_changes = true,
-- 	},
-- 	columns = {
-- 		"icon",
-- 	},
-- 	float = {
-- 		max_width = 0.5,
-- 		max_height = 0.6,
-- 		border = "rounded",
-- 	},
-- 	-- Buffer-local options to use for oil buffers
-- 	buf_options = {
-- 		buflisted = true,
-- 		bufhidden = "hide",
-- 	},
-- 	delete_to_trash = false,
-- 	skip_confirm_for_simple_edits = false,
-- 	prompt_save_on_select_new_entry = true,
-- 	-- Constrain the cursor to the editable parts of the oil buffer
-- 	-- Set to `false` to disable, or "name" to keep it on the file names
-- 	constrain_cursor = "editable",
-- 	-- Set to true to watch the filesystem for changes and reload oil
-- 	watch_for_changes = false,
-- 	view_options = {
-- 		show_hidden = true,
-- 	},
-- })

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
		follow_current_file = {
			enabled = true,
			leave_dirs_open = false,
		},
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

map({ "n", "i", "v" }, "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map(
	{ "n", "i", "v" },
	"<leader>xX",
	"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
	{ desc = "Buffer Diagnostics (Trouble)" }
)
map({ "n", "i", "v" }, "<leader>cs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols (Trouble)" })
map(
	{ "n", "i", "v" },
	"<leader>cS",
	"<cmd>Trouble lsp toggle<cr>",
	{ desc = "LSP references/definitions/... (Trouble)" }
)
map({ "n", "i", "v" }, "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
map({ "n", "i", "v" }, "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
map({ "n", "i", "v" }, "[q", function()
	if require("trouble").is_open() then
		require("trouble").prev({ skip_groups = true, jump = true })
	else
		local ok, err = pcall(vim.cmd.cprev)
		if not ok then
			vim.notify(err, vim.log.levels.ERROR)
		end
	end
end)

map({ "n", "i", "v" }, "]q", function()
	if require("trouble").is_open() then
		require("trouble").next({ skip_groups = true, jump = true })
	else
		local ok, err = pcall(vim.cmd.cnext)
		if not ok then
			vim.notify(err, vim.log.levels.ERROR)
		end
	end
end)
