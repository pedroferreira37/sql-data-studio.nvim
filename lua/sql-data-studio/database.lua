local M = {}

local COMMAND = "SELECT * FROM STORE_PROCEDURES"

local connect_db = function()
	print("working")
end

M.find_sp = function()
	connect_db()
end

return M
