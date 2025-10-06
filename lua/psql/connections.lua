--[[
  psql.nvim - Connection Management
  Parses, stores, and retrieves connection details from the config.
]]

local config = require("psql.config")
local crypto = require("psql.crypto")

local M = {}

-- Internal storage for parsed connections
local loaded_connections = {}

--- Parses a PostgreSQL URL into its components.
--- @param url string The connection URL.
--- @return table|nil A table with connection details or nil on failure.
local function parse_url(url)
	-- Pattern for postgresql://user:password@host:port/dbname
	local pattern = "postgresql://([^:]*):?([^@]*)@([^:]*):?(%d*)/?(.*)"
	local user, password, host, port, dbname = url:match(pattern)

	if not host then
		vim.notify("PSQL: Invalid connection URL format: " .. url, vim.log.levels.ERROR)
		return nil
	end

	return {
		user = user and #user > 0 and user or nil,
		password = password and #password > 0 and password or nil,
		host = host,
		port = port and #port > 0 and tonumber(port) or 5432,
		dbname = dbname and #dbname > 0 and dbname or nil,
	}
end

--- Loads and processes connections from the global config.
function M.load()
	loaded_connections = {}
	for _, conn_config in ipairs(config.config.connections) do
		local details
		if conn_config.url then
			details = parse_url(conn_config.url)
		else
			details = {
				host = conn_config.host,
				port = conn_config.port or 5432,
				user = conn_config.user,
				password = conn_config.password,
				dbname = conn_config.dbname,
			}
		end

		if details then
			if details.password then
				details.encrypted_password = crypto.encrypt(details.password)
				details.password = nil -- Don't keep plaintext password in memory
			end

			table.insert(loaded_connections, {
				name = conn_config.name,
				details = details,
			})
		end
	end
end

--- Returns a list of all configured connection names.
--- @return string[]
function M.get_connection_names()
	local names = {}
	for _, conn in ipairs(loaded_connections) do
		table.insert(names, conn.name)
	end
	return names
end

--- Retrieves full connection details by its name.
--- @param name string The name of the connection.
--- @return table|nil The connection object or nil if not found.
function M.get_connection_by_name(name)
	for _, conn in ipairs(loaded_connections) do
		if conn.name == name then
			return conn
		end
	end
	return nil
end

return M
