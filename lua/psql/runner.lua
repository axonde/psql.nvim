--[[
  psql.nvim - PSQL Command Runner
]]

local M = {}

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

function M.open_shell(conn_details)
	local args = prepare_args(conn_details)
	local term_opts = { env = {} }
	if conn_details.password then
		term_opts.env.PGPASSWORD = conn_details.password
	end
	vim.cmd("enew")
	vim.fn.termopen(args, term_opts)
	vim.cmd("startinsert")
end

function M.execute_query(conn_details, query, callback)
	local args = prepare_args(conn_details)
	vim.list_extend(args, { "-w", "-c", query })

	local env_vars = { "PATH=" .. os.getenv("PATH") }
	local passfile_path

	if conn_details.password then
		passfile_path = vim.fn.tempname()
		local passfile, err = io.open(passfile_path, "w")
		if not passfile then
			vim.notify("PSQL: Could not create temp password file: " .. err, vim.log.levels.ERROR)
		else
			local function escape(s)
				return (s or ""):gsub("([:\\\\])", "\\%1")
			end
			local host = escape(conn_details.host)
			local port = escape(tostring(conn_details.port))
			local dbname = escape(conn_details.dbname)
			local user = escape(conn_details.user)
			passfile:write(string.format("%s:%s:%s:%s:%s", host, port, dbname, user, conn_details.password))
			passfile:close()
			vim.fn.setfperm(passfile_path, "rw-------")
			table.insert(env_vars, "PGPASSFILE=" .. passfile_path)
		end
	end

	local stdout, stderr = vim.loop.new_pipe(false), vim.loop.new_pipe(false)
	local stdout_chunks, stderr_chunks = {}, {}

	local handle
	handle = vim.loop.spawn(args[1], {
		args = vim.list_slice(args, 2),
		env = env_vars,
		stdio = { nil, stdout, stderr },
	}, function(code)
		stdout:close()
		stderr:close()
		if handle and not handle:is_closing() then
			handle:close()
		end
		if passfile_path then
			os.remove(passfile_path)
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
