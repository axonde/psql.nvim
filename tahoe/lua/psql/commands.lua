local M = {}

local connections = require("psql.connections")
local buffer = require("psql.buffer")
local ui = require("psql.ui")

-- Register Vim commands
function M.register()
	-- Execute SQL query
	vim.cmd([[
    command! -nargs=? -range PSQLExecuteQuery lua require('psql.commands').execute_query(<q-args>, <line1>, <line2>)
  ]])

	-- Execute entire file
	vim.cmd([[
    command! PSQLExecuteFile lua require('psql.commands').execute_file()
  ]])

	-- List connections
	vim.cmd([[
    command! PSQLListConnections lua require('psql.commands').list_connections()
  ]])

	-- Add connection
	vim.cmd([[
    command! PSQLAddConnection lua require('psql.commands').add_connection()
  ]])

	-- Edit connection
	vim.cmd([[
    command! -nargs=1 PSQLEditConnection lua require('psql.commands').edit_connection(<f-args>)
  ]])

	-- Remove connection
	vim.cmd([[
    command! -nargs=1 PSQLRemoveConnection lua require('psql.commands').remove_connection(<f-args>)
  ]])

	-- Set active connection
	vim.cmd([[
    command! -nargs=1 PSQLSetActiveConnection lua require('psql.commands').set_active_connection(<f-args>)
  ]])

	-- Register keymaps
	M.register_keymaps()
end

-- Register keymaps
function M.register_keymaps()
	local config = require("psql.config")
	local keymaps = config.get("keymaps")

	-- Query execution
	vim.api.nvim_set_keymap(
		"n",
		keymaps.execute_query,
		"<cmd>PSQLExecuteQuery<CR>",
		{ noremap = true, silent = true, desc = "Execute SQL under cursor" }
	)

	-- File execution
	vim.api.nvim_set_keymap(
		"n",
		keymaps.execute_file,
		"<cmd>PSQLExecuteFile<CR>",
		{ noremap = true, silent = true, desc = "Execute entire SQL file" }
	)

	-- List connections
	vim.api.nvim_set_keymap(
		"n",
		keymaps.list_connections,
		"<cmd>PSQLListConnections<CR>",
		{ noremap = true, silent = true, desc = "List PostgreSQL connections" }
	)

	-- Add connection
	vim.api.nvim_set_keymap(
		"n",
		keymaps.add_connection,
		"<cmd>PSQLAddConnection<CR>",
		{ noremap = true, silent = true, desc = "Add PostgreSQL connection" }
	)

	-- Visual mode execution
	vim.api.nvim_set_keymap(
		"v",
		keymaps.execute_query,
		":PSQLExecuteQuery<CR>",
		{ noremap = true, silent = true, desc = "Execute selected SQL" }
	)
end

-- Execute query
function M.execute_query(args, line1, line2)
	local query = args

	-- If no args provided, use selection or current paragraph
	if not query or query == "" then
		if line1 ~= line2 then
			-- Visual selection
			query = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
			query = table.concat(query, "\n")
		else
			-- Current paragraph
			local cursor = vim.api.nvim_win_get_cursor(0)
			local start_line = cursor[1]
			local end_line = cursor[1]

			-- Find start of paragraph
			while start_line > 1 do
				local line = vim.api.nvim_buf_get_lines(0, start_line - 2, start_line - 1, false)[1]
				if line:match("^%s*$") then
					break
				end
				start_line = start_line - 1
			end

			-- Find end of paragraph
			local buf_line_count = vim.api.nvim_buf_line_count(0)
			while end_line < buf_line_count do
				local line = vim.api.nvim_buf_get_lines(0, end_line, end_line + 1, false)[1]
				if line:match("^%s*$") then
					break
				end
				end_line = end_line + 1
			end

			query = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
			query = table.concat(query, "\n")
		end
	end

	-- Execute query
	local results, err = connections.execute_query(query)
	if err then
		vim.notify("Error executing query: " .. err, vim.log.levels.ERROR)
		return
	end

	-- Create buffer and display results
	local buf = buffer.create_results_buffer(query, results)
	buffer.display_buffer(buf)
end

-- Execute file
function M.execute_file()
	local filename = vim.api.nvim_buf_get_name(0)
	local file = io.open(filename, "r")

	if not file then
		vim.notify("Failed to open file", vim.log.levels.ERROR)
		return
	end

	local content = file:read("*all")
	file:close()

	-- Execute query
	local results, err = connections.execute_query(content)
	if err then
		vim.notify("Error executing file: " .. err, vim.log.levels.ERROR)
		return
	end

	-- Create buffer and display results
	local buf = buffer.create_results_buffer("File: " .. vim.fn.fnamemodify(filename, ":t"), results)
	buffer.display_buffer(buf)
end

-- List connections
function M.list_connections()
	local conns = connections.list()
	ui.show_connections(conns)
end

-- Add connection
function M.add_connection()
	ui.add_connection_form(function(conn_details)
		local success, msg = connections.add(conn_details)
		vim.notify(msg, success and vim.log.levels.INFO or vim.log.levels.ERROR)
	end)
end

-- Edit connection
function M.edit_connection(name)
	ui.edit_connection_form(name, function(conn_details)
		local success, msg = connections.edit(name, conn_details)
		vim.notify(msg, success and vim.log.levels.INFO or vim.log.levels.ERROR)
	end)
end

-- Remove connection
function M.remove_connection(name)
	local success, msg = connections.remove(name)
	vim.notify(msg, success and vim.log.levels.INFO or vim.log.levels.ERROR)
end

-- Set active connection
function M.set_active_connection(name)
	local success, msg = connections.set_active(name)
	vim.notify(msg, success and vim.log.levels.INFO or vim.log.levels.ERROR)
end

return M
