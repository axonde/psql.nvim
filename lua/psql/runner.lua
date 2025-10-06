--[[
  psql.nvim - PSQL Command Runner
  Handles executing psql commands and displaying their output.
]]

local config = require("psql.config")
local crypto = require("psql.crypto")

local M = {}

--- Prepares the environment and arguments for a psql command.
--- @param conn_details table The connection details object.
--- @return table, table Environment variables and command arguments.
local function prepare_command(conn_details)
	local env = {}
	if conn_details.encrypted_password then
		env.PGPASSWORD = crypto.decrypt(conn_details.encrypted_password)
	end

	local args = { "psql" }
	if conn_details.host then
		vim.list_extend(args, { "-h", conn_details.host })
	end
	if conn_details.port then
		vim.list_extend(args, { "-p", tostring(conn_details.port) })
	end
	if conn_details.user then
		vim.list_extend(args, { "-U", conn_details.user })
	end
	if conn_details.dbname then
		vim.list_extend(args, { "-d", conn_details.dbname })
	end

	return env, args
end

--- Opens an interactive psql shell for a given connection.
--- @param conn_details table
function M.open_shell(conn_details)
	local env, args = prepare_command(conn_details)
	local cmd_string = table.concat(args, " ")

	local term_command
	if env.PGPASSWORD then
		-- ИСПРАВЛЕНО: Экранируем одинарные кавычки в пароле для оболочки.
		-- Заменяем ' на '\''.
		local escaped_password = env.PGPASSWORD:gsub("'", "'\\''")

		-- Устанавливаем переменную окружения только для этой команды, чтобы она не попала в историю.
		term_command = string.format("env PGPASSWORD='%s' %s", escaped_password, cmd_string)
	else
		term_command = cmd_string
	end

	-- Используем :terminal для большей надежности при передаче сложных команд.
	vim.cmd("enew | terminal " .. term_command)
end

--- Executes a non-interactive query and returns the output.
--- @param conn_details table
--- @param query string The SQL query to execute.
--- @param callback function A function to call with the output (stdout, stderr, code).
function M.execute_query(conn_details, query, callback)
	local env, args = prepare_command(conn_details)
	vim.list_extend(args, { "-c", query })

	local stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)
	local stdout_chunks = {}
	local stderr_chunks = {}

	local handle
	handle = vim.loop.spawn(args[1], {
		args = vim.list_slice(args, 2),
		env = env,
		stdio = { nil, stdout, stderr },
	}, function(code)
		stdout:close()
		stderr:close()
		if handle and not handle:is_closing() then
			handle:close()
		end
		callback(table.concat(stdout_chunks), table.concat(stderr_chunks), code)
	end)

	vim.loop.read_start(stdout, function(_, data)
		if data then
			table.insert(stdout_chunks, data)
		end
	end)
	vim.loop.read_start(stderr, function(_, data)
		if data then
			table.insert(stderr_chunks, data)
		end
	end)
end

return M
