local M = {}

local DEFAULT_MIN_WIDTH = 30

local BUFNR_PER_TAB = {}

local move_tbl = {
	left = "H",
	right = "L",
}

M.View = {
	side = "left",
	tabpages = {},
	cursors = {},
	tab = {
		sync = {
			close = false,
		},
	},

	winopts = {
		relativenumber = false,
		number = false,
		list = false,
		foldenable = false,
		winfixwidth = true,
		winfixheight = true,
		spell = false,
		signcolumn = "yes",
		foldmethod = "manual",
		foldcolumn = "0",
		cursorcolumn = false,
		cursorline = true,
		cursorlineopt = "both",
		colorcolumn = "0",
		wrap = false,
	},
}

local BUFFER_OPTIONS = {
	swapfile = false,
	buftype = "nofile",
	modifiable = false,
	filetype = "SQLTree",
	bufhidden = "wipe",
	buflisted = false,
}

local tabinitial = {
	cursor = { 0, 0 },
	winr = nil,
}

local function setup_tabpage(tabpage)
	local winnr = vim.api.nvim_get_current_win()
	M.View.tabpages[tabpage] = vim.tbl_extend("force", M.View.tabpages[tabpage] or tabinitial, { winnr = winnr })
end

local function set_win_options_and_buf()
	pcall(vim.cmd, "buffer " .. M.get_bufnr())
	for k, v in pairs(M.View.winopts) do
		vim.opt_local[k] = v
	end
end

--[[
-- this represents how tabs and buffer can be arrangended
 const tabs = {
  tab_1: buffernr,
tab_2: buffers
}

const bfnr = tabs[tab_1]
--]]

local function matches_bufnr(bufnr)
	for _, b in pairs(BUFNR_PER_TAB) do
		if b == bufnr then
			return true
		end
	end
	return false
end

local function wipe_rogue_buffer()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if not matches_bufnr(bufnr) then
			pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
		end
	end
end

function M.get_winnr(tabpage)
	tabpage = tabpage or vim.api.nvim_get_current_tabpage()
	local tabinfo = M.View.tabpages[tabpage]
	if tabinfo ~= nil then
		return tabinfo.winnr
	end
end

function M.reposition_window()
	local move_to = move_tbl[M.View.side]
	vim.api.nvim_command("wincmd " .. move_to)
end

function M.restore_tab_state()
	local tabpage = vim.api.nvim_get_current_tabpage()
	M.set_cursor(M.View.cursors[tabpage])
end

local function create_buff(bufnr)
	wipe_rogue_buffer()

	local tab = vim.api.nvim_get_current_tabpage()
	BUFNR_PER_TAB[tab] = bufnr or vim.api.nvim_create_buf(false, false)
	vim.api.nvim_buf_set_name(M.get_bufnr(), "SQLTree_" .. tab)

	for k, v in pairs(BUFFER_OPTIONS) do
		vim.bo[M.get_bufnr()][k] = v
	end
end

local function open_win()
	vim.api.nvim_command("vsp")
	M.reposition_window()
	setup_tabpage(vim.api.nvim_get_current_tabpage())
	set_win_options_and_buf()
end

function M.get_bufnr()
	return BUFNR_PER_TAB[vim.api.nvim_get_current_tabpage()]
end

function M.resize()
	vim.api.nvim_win_set_width(M.get_winnr(), DEFAULT_MIN_WIDTH)
end

-- the tree is not closing correctly causing it to open in a wrong way

function M.open()
	if M.is_visible() then
		return
	end

	create_buff()
	open_win()
	M.resize()
end

local function save_tab_state(tabnr)
	local tabpage = tabnr or vim.api.nvim_get_current_tabpage()
	M.View.cursors[tabpage] = vim.api.nvim_win_get_cursor(M.get_winnr(tabpage))
end

function M.is_visible(opts)
	if opts and opts.tabpage then
		if M.View.tabpages[opts.tabpage] == nil then
			return false
		end
		local winnr = M.View.tabpages[opts.tabpage].winnr
		return winnr and vim.api.nvim_win_is_valid(winnr)
	end
end

local function is_buf_displayed(buf)
	return vim.api.nvim_buf_is_valid(buf) and vim.fn.buflisted(buf) == 1
end

local function get_alt_or_next_buf()
	local alt_buf = vim.fn.bufnr("#")
	if is_buf_displayed(alt_buf) then
		return alt_buf
	end

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if is_buf_displayed(buf) then
			return buf
		end
	end
end

local function switch_buf_if_last_buf()
	if #vim.api.nvim_list_wins() == 1 then
		local buf = get_alt_or_next_buf()
		if buf then
			vim.cmd("sb" .. buf)
		else
			vim.cmd("new")
		end
	end
end

local function close(tabpage)
	if not M.is_visible({ tabpage = tabpage }) then
		return
	end

	save_tab_state(tabpage)
	switch_buf_if_last_buf()

	local tree_win = M.get_winnr(tabpage)
	local current_win = vim.api.nvim_get_current_win()
	for _, win in pairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
		if vim.api.nvim_win_get_config(win).relative == "" then
			local prev_win = vim.fn.winnr("#") -- this tab only
			if tree_win == current_win and prev_win > 0 then
				vim.api.nvim_set_current_win(vim.fn.win_getid(prev_win))
			end
			if vim.api.nvim_win_is_valid(tree_win) then
				vim.api.nvim_win_close(tree_win, true)
			end
			return
		end
	end
end

function M.close_this_tab_only()
	close(vim.api.nvim_get_current_tabpage())
end

function M.close_all_tabs()
	for tabpage, _ in pairs(M.View.tabpages) do
		close(tabpage)
	end
end

function M.close()
	if M.View.tab.sync.close then
		M.close_all_tabs()
	else
		M.close_this_tab_only()
	end
end

function M.toggle()
	if M.is_visible() then
		M.close()
	else
		M.open()
	end
	M.restore_tab_state()
end

return M
