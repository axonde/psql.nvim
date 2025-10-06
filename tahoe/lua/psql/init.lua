local M = {}

local config = require("psql.config")
local connections = require("psql.connections")
local commands = require("psql.commands")

-- Setup function to initialize the plugin with user config
function M.setup(opts)
	-- Merge user config with defaults
	config.setup(opts)

	-- Initialize connections from stored data
	connections.init()

	-- Register plugin commands
	commands.register()

	-- Return the configured module
	return M
end

-- Execute a query on the current/specified connection
function M.execute_query(query, connection_name)
	return connections.execute_query(query, connection_name)
end

-- Add a new connection
function M.add_connection(conn_details)
	return connections.add(conn_details)
end

-- List available connections
function M.list_connections()
	return connections.list()
end

-- Remove a connection
function M.remove_connection(name)
	return connections.remove(name)
end

-- Edit connection details
function M.edit_connection(name, updated_details)
	return connections.edit(name, updated_details)
end

-- Set active connection
function M.set_active_connection(name)
	return connections.set_active(name)
end

return M
