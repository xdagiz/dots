local M = {}

vim.api.nvim_set_hl(0, "ZoomIndicator", { link = "DiagnosticWarn", default = true })

local state = {
	win = nil, ---@type number?
	indicator = nil, ---@type number?
	parent_win = nil, ---@type number?
	parent_view = nil, ---@type table?
	augroup = nil, ---@type number?
}

local function get_main()
	local bottom = vim.o.cmdheight + (vim.o.laststatus == 3 and 1 or 0)
	local top = (vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1)) and 1 or 0
	return {
		row = top,
		height = vim.o.lines - top - bottom,
	}
end

local function close_indicator()
	if state.indicator and vim.api.nvim_win_is_valid(state.indicator) then
		pcall(vim.api.nvim_win_close, state.indicator, true)
	end
	state.indicator = nil
end

local function open_indicator(win_zindex)
	close_indicator()

	local text = "▍ zoom  󰊓  "
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

	local width = vim.fn.strdisplaywidth(text)
	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		width = width,
		height = 1,
		row = 0,
		col = vim.o.columns - width,
		style = "minimal",
		border = "none",
		zindex = win_zindex + 1,
		focusable = false,
	})

	local wo = vim.wo[win]
	wo.winhighlight = "NormalFloat:ZoomIndicator"
	state.indicator = win
end

local function close()
	if not state.win or not vim.api.nvim_win_is_valid(state.win) then
		return
	end

	close_indicator()

	if state.parent_win and vim.api.nvim_win_is_valid(state.parent_win) then
		pcall(vim.api.nvim_win_call, state.parent_win, function()
			pcall(vim.fn.winrestview, state.parent_view or {})
		end)
	end

	pcall(vim.api.nvim_win_close, state.win, true)
	state.win = nil
end

function M.zoom()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		close()
		return
	end

	state.parent_win = vim.api.nvim_get_current_win()
	state.parent_view = vim.api.nvim_win_call(state.parent_win, vim.fn.winsaveview)

	local parent_zindex = vim.api.nvim_win_get_config(state.parent_win).zindex
	local zoom_zindex = parent_zindex and parent_zindex + 1 or 50

	local buf = vim.api.nvim_get_current_buf()

	local main
	if vim.o.cmdheight > 0 or vim.o.laststatus == 3 or vim.o.showtabline > 0 then
		main = get_main()
	else
		main = { row = 0, height = vim.o.lines }
	end

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = vim.o.columns,
		height = main.height,
		row = main.row,
		col = 0,
		border = "none",
		zindex = zoom_zindex,
	})

	local wo = vim.wo[win]

	open_indicator(zoom_zindex)

	if state.augroup then
		pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
	end
	state.augroup = vim.api.nvim_create_augroup("zoom_cursor_sync", { clear = true })

	vim.api.nvim_create_autocmd("CursorMoved", {
		group = state.augroup,
		buffer = buf,
		callback = function()
			if not state.parent_win or not vim.api.nvim_win_is_valid(state.parent_win) then
				return
			end
			if not state.win or not vim.api.nvim_win_is_valid(state.win) then
				return
			end
			pcall(vim.api.nvim_win_set_cursor, state.parent_win, vim.api.nvim_win_get_cursor(state.win))
		end,
	})

	vim.api.nvim_create_autocmd("WinEnter", {
		group = state.augroup,
		callback = function()
			if not state.win or not vim.api.nvim_win_is_valid(state.win) then
				return
			end
			local cur = vim.api.nvim_get_current_win()
			if cur == state.win then
				return
			end
			if vim.api.nvim_win_get_config(cur).relative == "" then
				vim.schedule(close)
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufUnload", {
		group = state.augroup,
		buffer = buf,
		callback = close,
	})

	state.win = win
end

return M
