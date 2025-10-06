local M = {}

local config = require("psql.config")
local encryption = require("psql.encryption")

-- Internal storage for connections
local connections = {}
local active_connection = nil

-- File path for storing connections
local connections_file = config.get("storage_path") .. "/connections.json"

-- Encode connection data for storage (encrypting sensitive fields)
local function encode_connection(conn)
	local encoded = vim.deepcopy(conn)

	-- Encrypt password if present
	if conn.password and config.get("store_password") then
		encoded.password = encryption.encrypt(conn.password)
	else
		encoded.password = nil -- Don't store passwords unless configured to do so
	end

	return encoded
end

-- Decode connection data from storage (decrypting sensitive fields)
local function decode_connection(encoded)
	local conn = vim.deepcopy(encoded)

	-- Decrypt password if present
	if encoded.password then
		conn.password = encryption.decrypt(encoded.password)
	end

	return conn
end

-- Save connections to disk
local function save_connections()
	local encoded_connections = {}

	for name, conn in pairs(connections) do
		encoded_connections[name] = encode_connection(conn)
	end

	local json = vim.fn.json_encode(encoded_connections)
	local file = io.open(connections_file, "w")
	if file then
		file:write(json)
		file:close()
		return true
	end

	return false
end

-- Load connections from disk
local function load_connections()
	local file = io.open(connections_file, "r")
	if not file then
		return false
	end

	local content = file:read("*all")
	file:close()

	if not content or content == "" then
		return false
	end

	local encoded_connections = vim.fn.json_decode(content)
	if not encoded_connections then
		return false
	end

	for name, encoded in pairs(encoded_connections) do
		connections[name] = decode_connection(encoded)
	end

	return true
end

-- Connect to a PostgreSQL database
local function connect(conn_details)
	local postgres = require("psql.postgres")
	return postgres.connect(conn_details)
end

-- Initialize connections
function M.init()
	-- First try to load from config
	local config_connections = config.get("connections")
	for name, conn in pairs(config_connections or {}) do
		connections[name] = conn
	end

	-- Then load from file, which will override config if names match
	load_connections()

	-- Set first connection as active if none active
	if not active_connection and next(connections) then
		active_connection = next(connections)
	end
end

-- Add a new connection
function M.add(conn_details)
	if not conn_details.name then
		return false, "Connection name is required"
	end

	-- Set default values if not provided
	conn_details.port = conn_details.port or config.get("default_port")
	conn_details.user = conn_details.user or config.get("default_user")

	-- Store connection
	connections[conn_details.name] = conn_details

	-- Set as active if it's the first connection
	if not active_connection then
		active_connection = conn_details.name
	end

	-- Save to disk
	save_connections()

	return true, "Connection added successfully"
end

-- List all connections
function M.list()
	local result = {}
	for name, conn in pairs(connections) do
		table.insert(result, {
			name = name,
			host = conn.host,
			port = conn.port,
			database = conn.database,
			user = conn.user,
			active = (name == active_connection),
		})
	end

	return result
end

-- Remove a connection
function M.remove(name)
	if not connections[name] then
		return false, "Connection not found"
	end

	connections[name] = nil

	-- Reset active connection if it was the removed one
	if active_connection == name then
		active_connection = next(connections)
	end

	-- Save to disk
	save_connections()

	return true, "Connection removed successfully"
end

-- Edit a connection
function M.edit(name, updated_details)
	if not connections[name] then
		return false, "Connection not found"
	end

	-- Update connection details
	for k, v in pairs(updated_details) do
		connections[name][k] = v
	end

	-- Save to disk
	save_connections()

	return true, "Connection updated successfully"
end

-- Set active connection
function M.set_active(name)
	if not connections[name] then
		return false, "Connection not found"
	end

	active_connection = name
	return true, "Active connection set to " .. name
end

-- Get active connection
function M.get_active()
	if not active_connection then
		return nil, "No active connection"
	end

	return connections[active_connection]
end

-- Execute a query on the specified or active connection
function M.execute_query(query, connection_name)
	local conn_name = connection_name or active_connection
	if not conn_name then
		return nil, "No active connection"
	end

	local conn = connections[conn_name]
	if not conn then
		return nil, "Connection not found"
	end

	-- Get password if not stored
	if not conn.password and not config.get("store_password") then
		conn.password = vim.fn.inputsecret("Enter password for " .. conn_name .. ": ")
	end

	-- Execute query
	local postgres = require("psql.postgres")
	local results, err = postgres.execute_query(conn, query)

	return results, err
end

return M
