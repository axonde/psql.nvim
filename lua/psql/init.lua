--[[
  psql.nvim - Main Module
  Handles setup and exposes the public API.
]]

local config = require("psql.config")
local connections = require("psql.connections")
local ui = require("psql.ui")

local M = {}

--- @public
--- @param user_config table User configuration to merge with defaults.
function M.setup(user_config)
	if vim.fn.executable("psql") == 0 then
		vim.notify("PSQL: `psql` command not found in your PATH.", vim.log.levels.ERROR)
		return
	end

	config.setup(user_config)
	connections.load()

	vim.notify("psql.nvim loaded successfully!", vim.log.levels.INFO)
end

-- Expose other modules for advanced users if needed
M.ui = ui
M.connections = connections
M.config = config.config

return M
