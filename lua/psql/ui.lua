--[[
  psql.nvim - User Interface
  Handles user interactions like connection selection and output display.
]]

local connections = require("psql.connections")
local runner = require("psql.runner")
local config = require("psql.config")

local M = {}

--- Displays query results in a new buffer.
--- @param output string The text to display.
--- @param filetype string The filetype for the new buffer.
local function display_in_buffer(output, filetype)
	-- Если вывод пустой, ничего не делаем, чтобы не открывать пустые окна.
	if not output or #output == 0 then
		vim.notify("PSQL: Query produced no output.", vim.log.levels.INFO)
		return
	end

	local strategy = config.options.runner_output
	if strategy == "term" then
		vim.cmd("enew")
		vim.cmd("setlocal buftype=nofile bufhidden=wipe noswapfile")
		vim.api.nvim_buf_set_name(0, "psql_output")
		vim.fn.termopen("psql", {
			on_stdout = function(_, data)
				vim.api.nvim_buf_set_lines(0, -1, -1, false, data)
			end,
		})
		vim.api.nvim_chan_send(vim.b.terminal_job_id, output)
		return
	end

	if strategy == "split" then
		vim.cmd("new")
	elseif strategy == "vsplit" then
		vim.cmd("vnew")
	else
		vim.cmd("new")
	end

	vim.bo.filetype = filetype
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false
	vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, "\n"))
end

--- Generic function to execute a query on a selected connection.
--- @param query_provider function A function that returns the query string.
--- @param on_success function A function to handle the successful output.
local function execute_on_selection(query_provider, on_success)
	local conn_names = connections.get_connection_names()
	if #conn_names == 0 then
		vim.notify("PSQL: No connections configured. See :h psql.nvim for help.", vim.log.levels.WARN)
		return
	end

	vim.ui.select(conn_names, { prompt = "PSQL: Execute on which connection?" }, function(choice)
		if not choice then
			return
		end
		local conn = connections.get_connection_by_name(choice)
		if not conn then
			return
		end

		local query = query_provider()
		if not query or #query == 0 then
			vim.notify("PSQL: No query to execute.", vim.log.levels.INFO)
			return
		end

		vim.notify("PSQL: Executing query...", vim.log.levels.INFO)
		runner.execute_query(conn.details, query, function(stdout, stderr, code)
			vim.schedule(function()
				-- ИСПРАВЛЕНО: Улучшенная логика обработки вывода.
				if code == 0 then
					vim.notify("PSQL: Query executed successfully.", vim.log.levels.INFO)
					on_success(stdout)
				else
					-- Если код ошибки не 0, показываем stderr.
					-- Это поможет увидеть ошибки подключения, пароля и т.д.
					vim.notify("PSQL: Query failed. See output for details.", vim.log.levels.ERROR)
					display_in_buffer(stderr, "text")
				end
			end)
		end)
	end)
end

--- Opens a selection menu for connections and opens a shell for the selected one.
function M.select_and_connect()
	local conn_names = connections.get_connection_names()
	if #conn_names == 0 then
		vim.notify("PSQL: No connections configured. See :h psql.nvim for help.", vim.log.levels.WARN)
		return
	end

	vim.ui.select(conn_names, { prompt = "PSQL: Select Connection" }, function(choice)
		if not choice then
			return
		end
		local conn = connections.get_connection_by_name(choice)
		if conn then
			runner.open_shell(conn.details)
		end
	end)
end

--- Executes the content of the current buffer.
function M.execute_current_buffer()
	local get_query = function()
		return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	end
	execute_on_selection(get_query, function(output)
		display_in_buffer(output, "psql")
	end)
end

--- Lists databases for a selected connection.
function M.list_databases()
	execute_on_selection(function()
		return "\\l"
	end, function(output)
		display_in_buffer(output, "psql")
	end)
end

return M
