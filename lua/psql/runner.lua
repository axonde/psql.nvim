--[[
  psql.nvim - PSQL Command Runner
  Handles executing psql commands and displaying their output.
]]

local config = require("psql.config")
local crypto = require("psql.crypto")

local M = {}

--- Prepares the arguments for a psql command.
--- @param conn_details table The connection details object.
--- @return table Command arguments.
local function prepare_args(conn_details)
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

	return args
end

--- Opens an interactive psql shell for a given connection.
--- @param conn_details table
function M.open_shell(conn_details)
	local args = prepare_args(conn_details)
	local term_opts = {
		env = {},
		on_exit = function(_, code)
			vim.schedule(function()
				vim.notify(string.format("PSQL session exited with code %d", code), vim.log.levels.INFO)
			end)
		end,
	}

	if conn_details.encrypted_password then
		term_opts.env.PGPASSWORD = crypto.decrypt(conn_details.encrypted_password)
	end

	vim.cmd("enew")
	vim.fn.termopen(args, term_opts)
	vim.cmd("startinsert")
end

--- Executes a non-interactive query and returns the output.
--- @param conn_details table
--- @param query string The SQL query to execute.
--- @param callback function A function to call with the output (stdout, stderr, code).
function M.execute_query(conn_details, query, callback)
	local args = prepare_args(conn_details)
	vim.list_extend(args, { "-c", query })

	-- ИСПРАВЛЕНО: Формируем переменные окружения в правильном формате "KEY=VALUE" для vim.loop.spawn.
	-- Это гарантирует, что PGPASSWORD будет передан и psql не будет "зависать" в ожидании пароля.
	local env_vars
	if conn_details.encrypted_password then
		env_vars = { "PGPASSWORD=" .. crypto.decrypt(conn_details.encrypted_password) }
	end

	local stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)
	local stdout_chunks = {}
	local stderr_chunks = {}

	local handle
	handle = vim.loop.spawn(args[1], {
		args = vim.list_slice(args, 2),
		env = env_vars, -- Передаем переменные в правильном формате
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
