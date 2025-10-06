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
--- This version is more robust and handles optional parts correctly.
--- @param url string The connection URL.
--- @return table|nil A table with connection details or nil on failure.
local function parse_url(url)
	-- A more robust pattern: postgresql://[user[:password]@]host[:port][/dbname]
	local _, _, user, password, host, port, dbname =
		url:find("^postgres[ql]*://(?:([^:@]+)(?::([^@]+))?@)?([^:/]+)(?::(%d+))?/(.*)$")

	if not host then
		vim.notify("PSQL: Invalid connection URL format: " .. url, vim.log.levels.ERROR)
		return nil
	end

	return {
		user = user and #user > 0 and user or nil,
		password = password and #password > 0 and password or nil,
		host = host,
		port = port and tonumber(port) or 5432,
		dbname = dbname and #dbname > 0 and dbname or nil,
	}
end

--- Loads and processes connections from the global config.
function M.load()
	loaded_connections = {}
	local user_connections = config.config.connections or {}

	if #user_connections == 0 then
		vim.notify("PSQL: No connections configured in `setup`.", vim.log.levels.WARN)
	end

	for _, conn_config in ipairs(user_connections) do
		if not conn_config.name then
			vim.notify("PSQL: A connection is missing a `name`. Skipping.", vim.log.levels.ERROR)
		else
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
