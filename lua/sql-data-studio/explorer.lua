local M = {}

local DEFAULT_MIN_WIDTH = 30
local DEFAULT_MAX_HEIGHT = -1

local BUFNR_PER_TAB = {}

local move_tbl = {
	left = "H",
	right = "L",
}

M.View = {
	side = "left",
	tabpages = {},
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

-- local function set_current_win()
-- 	local current_tab = vim.api.nvim_get_current_tabpage()
-- 	M.View.tabpages[current_tab].winnr = vim.api.nvim_get_current_win()
-- end

function M.get_bufnr()
	return BUFNR_PER_TAB[vim.api.nvim_get_current_tabpage()]
end

function M.resize()
	vim.api.nvim_win_set_width(M.get_winnr(), DEFAULT_MIN_WIDTH)
end

function M.open()
	create_buff()
	open_win()
	M.resize()
end

M.open()

return M
