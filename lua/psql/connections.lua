--[[
  psql.nvim - Connection Management
]]

local config = require("psql.config")

local M = {}

local loaded_connections = {}

local function parse_url(url)
	local rest = url:match("^postgres[ql]*://(.*)")
	if not rest then
		vim.notify("PSQL: Invalid connection URL format: " .. url, vim.log.levels.ERROR)
		return nil
	end

	local details = {}
	local user_pass, host_port_db = rest:match("([^@]+)@(.*)")

	if host_port_db then
		details.user, details.password = user_pass:match("([^:]+):?(.*)")
		if details.password == "" then
			details.password = nil
		end
		rest = host_port_db
	else
		details.password = nil
	end

	local host_port, dbname = rest:match("([^/]+)/?(.*)")
	if dbname and dbname ~= "" then
		details.dbname = dbname
	end

	details.host, details.port = host_port:match("([^:]+):?(%d*)")
	if details.port and details.port ~= "" then
		details.port = tonumber(details.port)
	else
		details.port = 5432
	end

	if not details.host then
		vim.notify("PSQL: Could not parse host from URL: " .. url, vim.log.levels.ERROR)
		return nil
	end

	return details
end

function M.load()
	loaded_connections = {}
	local user_connections = config.options.connections or {}

	if #user_connections == 0 then
		vim.notify("PSQL: No connections configured. See :h psql.nvim", vim.log.levels.WARN)
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
				table.insert(loaded_connections, {
					name = conn_config.name,
					details = details,
				})
			end
		end
	end
end

function M.get_connection_names()
	local names = {}
	for _, conn in ipairs(loaded_connections) do
		table.insert(names, conn.name)
	end
	return names
end

function M.get_connection_by_name(name)
	for _, conn in ipairs(loaded_connections) do
		if conn.name == name then
			return conn
		end
	end
	return nil
end

return M
