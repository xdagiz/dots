vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = " ",
		},
		texthl = {
			[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
			[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
			[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
			[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
		},
		numhl = {},
	},
	virtual_text = {
		spacing = 2,
		source = "if_many",
		prefix = "●",
	},
	underline = true,
	severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local bufnr = args.buf
		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		vim.lsp.inlay_hint.enable(true)
		map("n", "K", vim.lsp.buf.hover, "LSP Hover")
		map("n", "gd", vim.lsp.buf.definition, "Go to definition")
		map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
		map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
		map("n", "grr", vim.lsp.buf.references, "References")
		map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
		map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
		map({ "n", "v" }, "gra", vim.lsp.buf.code_action, "Code action")
		map("n", "<leader>cf", function()
			vim.lsp.buf.format({ async = true })
		end, "Format buffer")
	end,
})

vim.lsp.config("vtsls", {
	settings = {
		complete_function_calls = true,
		vtsls = {
			enableMoveToFileCodeAction = true,
			autoUseWorkspaceTsdk = true,
			experimental = {
				maxInlayHintLength = 30,
				completion = {
					enableServerSideFuzzyMatch = true,
				},
			},
		},
		typescript = {
			tsserver = {
				maxTsServerMemory = 1024,
			},
			updateImportsOnFileMove = { enabled = "always" },
			suggest = {
				completeFunctionCalls = true,
			},
			inlayHints = {
				enumMemberValues = { enabled = true },
				functionLikeReturnTypes = { enabled = true },
				parameterNames = { enabled = "literals" },
				parameterTypes = { enabled = true },
				propertyDeclarationTypes = { enabled = true },
				variableTypes = { enabled = false },
			},
		},
	},
})

vim.lsp.config("lua_ls", { settings = { Lua = { hint = true } } })
vim.lsp.config("gopls", {
	settings = {
		gopls = {
			gofumpt = true,
			codelenses = {
				gc_details = false,
				generate = true,
				regenerate_cgo = true,
				run_govulncheck = true,
				test = true,
				tidy = true,
				upgrade_dependency = true,
				vendor = true,
			},
			hints = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				compositeLiteralTypes = true,
				constantValues = true,
				functionTypeParameters = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
			analyses = {
				nilness = true,
				unusedparams = true,
				unusedwrite = true,
				useany = true,
			},
			maxMemory = 700,
			usePlaceholders = true,
			completeUnimported = true,
			staticcheck = true,
			directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
			semanticTokens = true,
		},
	},
})

vim.lsp.config("tsgo", {
	settings = {
		typescript = {
			tsserver = {
				maxTsServerMemory = 1024,
			},
			updateImportsOnFileMove = { enabled = "always" },
			suggest = {
				completeFunctionCalls = true,
			},
			inlayHints = {
				variableTypes = { enabled = false },
			},
		},
	},
})

vim.lsp.config("rust_analyzer", {
	settings = {
		["rust-analyzer"] = {
			cargo = {
				allFeatures = false,
				loadOutDirsFromCheck = false,
				buildScripts = { enable = false },
				runBuildScripts = false,
			},
			checkOnSave = false,
			diagnostics = { enable = false },
			procMacro = { enable = false },
			files = {
				exclude = {
					".direnv",
					".git",
					".jj",
					".github",
					".gitlab",
					"bin",
					"node_modules",
					"target",
					"venv",
					".venv",
				},
				watcher = "client",
			},
			linkedProjects = {},
		},
	},
})

vim.lsp.config("jsonls", {
	settings = {
		json = {
			format = {
				enable = true,
			},
			schemas = {
				{
					description = "NPM configuration file",
					fileMatch = { "package.json" },
					name = "package.json",
					url = "https://www.schemastore.org/package.json",
				},
				{
					description = "YAML GitHub Actions",
					fileMatch = { "action.yml", "action.yaml" },
					name = "GitHub Action",
					url = "https://www.schemastore.org/github-action.json",
				},
				{
					description = "YAML GitHub Workflow",
					fileMatch = {
						"**/.github/workflows/*.yml",
						"**/.github/workflows/*.yaml",
						"**/.gitea/workflows/*.yml",
						"**/.gitea/workflows/*.yaml",
						"**/.forgejo/workflows/*.yml",
						"**/.forgejo/workflows/*.yaml",
					},
					name = "GitHub Workflow",
					url = "https://www.schemastore.org/github-workflow.json",
				},
			},
			validate = {
				enable = true,
			},
		},
	},
})

vim.lsp.enable({
	-- "lua_ls",
	-- "gopls",
	"oxlint",
	-- "bacon_ls",
	-- "rust_analyzer",
	-- "tailwindcss",
	-- "tsgo",
	"typos_lsp",
	-- "jsonls",
	-- "vtsls",
	-- "zls",
})
