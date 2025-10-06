local M = {}

-- Determine if psql is available
local function is_psql_available()
	local handle = io.popen("which psql 2>/dev/null || where psql 2>nul")
	if not handle then
		return false
	end

	local result = handle:read("*a")
	handle:close()

	return result and result ~= ""
end

-- Connection function - returns a connection object with methods
function M.connect(conn_details)
	-- Validate required fields
	if not conn_details.host or not conn_details.database or not conn_details.user then
		return nil, "Missing required connection details"
	end

	-- Create connection string
	local conn_string = string.format(
		"postgresql://%s:%s@%s:%s/%s",
		conn_details.user,
		conn_details.password or "",
		conn_details.host,
		conn_details.port or "5432",
		conn_details.database
	)

	-- Return connection object
	return {
		details = conn_details,
		conn_string = conn_string,
	}
end

-- Execute a query using psql command-line tool
function M.execute_query(conn_details, query)
	if not is_psql_available() then
		return nil, "psql command not found. Please install PostgreSQL client tools."
	end

	-- Build connection parameters
	local params = {
		"-h",
		conn_details.host,
		"-p",
		tostring(conn_details.port or 5432),
		"-U",
		conn_details.user,
		"-d",
		conn_details.database,
		"-c",
		query,
		"--no-password", -- Don't prompt for password
		"--tuples-only", -- Get only data rows
		"--no-align", -- Unaligned output mode
	}

	-- Add output format
	table.insert(params, "-F")
	table.insert(params, ",") -- CSV output for easier parsing

	-- Set password environment variable
	local env = "PGPASSWORD=" .. (conn_details.password or "")

	-- Execute command
	local cmd = "psql " .. table.concat(params, " ")
	local handle = io.popen(env .. " " .. cmd .. " 2>&1")
	if not handle then
		return nil, "Failed to execute psql command"
	end

	-- Read results
	local output = handle:read("*a")
	local success = handle:close()

	if not success then
		return nil, output
	end

	-- Parse CSV results
	local results = {}
	local header_line = true
	local headers = {}

	for line in output:gmatch("[^\r\n]+") do
		if header_line then
			-- Parse header line
			for col in line:gmatch("[^,]+") do
				table.insert(headers, col:match("^%s*(.-)%s*$"))
			end
			header_line = false
		else
			-- Parse data line
			local row = {}
			local col_index = 1

			for col in line:gmatch("[^,]+") do
				local value = col:match("^%s*(.-)%s*$")
				row[headers[col_index]] = value
				col_index = col_index + 1
			end

			table.insert(results, row)
		end
	end

	return results
end

return M
