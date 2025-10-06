local M = {}

local config = require("psql.config")

-- Show connection list in a buffer
function M.show_connections(connections)
	local buf = vim.api.nvim_create_buf(false, true)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_name(buf, "PostgreSQL Connections")

	-- Format connections as a table
	local lines = { "PostgreSQL Connections", "=====================", "" }

	if #connections == 0 then
		table.insert(lines, "No connections configured.")
		table.insert(lines, "")
		table.insert(lines, "Use :PSQLAddConnection to add a new connection.")
	else
		-- Add table header
		table.insert(
			lines,
			"| Name               | Host               | Port  | Database           | User               | Active |"
		)
		table.insert(
			lines,
			"|--------------------|--------------------|-------|--------------------|--------------------|--------|"
		)

		-- Add connections
		for _, conn in ipairs(connections) do
			local active_mark = conn.active and "✓" or " "
			table.insert(
				lines,
				string.format(
					"| %-18s | %-18s | %-5s | %-18s | %-18s | %-6s |",
					conn.name,
					conn.host,
					conn.port,
					conn.database,
					conn.user,
					active_mark
				)
			)
		end
	end

	-- Add help text
	table.insert(lines, "")
	table.insert(lines, "Commands:")
	table.insert(lines, "  :PSQLAddConnection         - Add a new connection")
	table.insert(lines, "  :PSQLEditConnection <name> - Edit a connection")
	table.insert(lines, "  :PSQLRemoveConnection <name> - Remove a connection")
	table.insert(lines, "  :PSQLSetActiveConnection <name> - Set active connection")

	-- Set buffer lines
	vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)

	-- Display buffer in a new window
	local display_mode = config.get("show_result_in")

	if display_mode == "float" then
		-- Create floating window
		local width = vim.api.nvim_get_option("columns")
		local height = vim.api.nvim_get_option("lines")

		local win_width = math.min(width - 10, 80)
		local win_height = math.min(height - 10, #lines + 2)

		local row = math.floor((height - win_height) / 2)
		local col = math.floor((width - win_width) / 2)

		local opts = {
			relative = "editor",
			width = win_width,
			height = win_height,
			row = row,
			col = col,
			style = "minimal",
			border = config.get("float_border"),
		}

		vim.api.nvim_open_win(buf, true, opts)
	else
		vim.cmd("split")
		vim.api.nvim_win_set_buf(0, buf)
	end

	-- Make buffer readonly
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "readonly", true)

	-- Set keymaps for connection management
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
end

-- Add connection form
function M.add_connection_form(callback)
	-- Create a form using vim.ui.input for each field
	local conn = {}

	local function ask_name()
		vim.ui.input({ prompt = "Connection name: " }, function(name)
			if not name or name == "" then
				return
			end
			conn.name = name
			ask_host()
		end)
	end

	local function ask_host()
		vim.ui.input({ prompt = "Host: ", default = "localhost" }, function(host)
			if not host or host == "" then
				return
			end
			conn.host = host
			ask_port()
		end)
	end

	local function ask_port()
		vim.ui.input({ prompt = "Port: ", default = tostring(config.get("default_port")) }, function(port)
			if not port or port == "" then
				conn.port = config.get("default_port")
			else
				conn.port = tonumber(port)
			end
			ask_database()
		end)
	end

	local function ask_database()
		vim.ui.input({ prompt = "Database: " }, function(database)
			if not database or database == "" then
				return
			end
			conn.database = database
			ask_user()
		end)
	end

	local function ask_user()
		vim.ui.input({ prompt = "User: ", default = config.get("default_user") }, function(user)
			if not user or user == "" then
				conn.user = config.get("default_user")
			else
				conn.user = user
			end
			ask_password()
		end)
	end

	local function ask_password()
		if not config.get("store_password") then
			callback(conn)
			return
		end

		vim.ui.input({ prompt = "Password: " }, function(password)
			conn.password = password
			callback(conn)
		end)
	end

	-- Start the form
	ask_name()
end

-- Edit connection form
function M.edit_connection_form(name, callback)
	local connections = require("psql.connections")
	local conns = connections.list()

	local conn_details
	for _, conn in ipairs(conns) do
		if conn.name == name then
			conn_details = conn
			break
		end
	end

	if not conn_details then
		vim.notify("Connection not found: " .. name, vim.log.levels.ERROR)
		return
	end

	-- Create a form using vim.ui.input for each field
	local updated_conn = {}

	local function ask_host()
		vim.ui.input({ prompt = "Host: ", default = conn_details.host }, function(host)
			if host and host ~= "" then
				updated_conn.host = host
			end
			ask_port()
		end)
	end

	local function ask_port()
		vim.ui.input({ prompt = "Port: ", default = tostring(conn_details.port) }, function(port)
			if port and port ~= "" then
				updated_conn.port = tonumber(port)
			end
			ask_database()
		end)
	end

	local function ask_database()
		vim.ui.input({ prompt = "Database: ", default = conn_details.database }, function(database)
			if database and database ~= "" then
				updated_conn.database = database
			end
			ask_user()
		end)
	end

	local function ask_user()
		vim.ui.input({ prompt = "User: ", default = conn_details.user }, function(user)
			if user and user ~= "" then
				updated_conn.user = user
			end
			ask_password()
		end)
	end

	local function ask_password()
		if not config.get("store_password") then
			callback(updated_conn)
			return
		end

		vim.ui.input({ prompt = "Password (leave empty to keep unchanged): " }, function(password)
			if password and password ~= "" then
				updated_conn.password = password
			end
			callback(updated_conn)
		end)
	end

	-- Start the form
	ask_host()
end

return M
