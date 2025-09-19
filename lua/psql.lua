local function is_sql_file(buf_name)
	return string.match(buf_name, ".sql$") ~= nil
end

local function get_connection_name(line)
	local connection_name = string.match(line, "^%s*%-%-%s*psql:(.*)")
	return connection_name
end

local function psql_run_ad_hoc(sql_command)
	local output_file = "/tmp/psql.nvim.out"
	local firstline = table.concat(vim.api.nvim_buf_get_lines(0, 0, 1, false), "")
	local connection_name = get_connection_name(firstline)
	if connection_name == nil or connection_name == "" then
		vim.notify(
			"Invalid psqlcm connection identifier. Should be finded in YOUR file (or where the selection is) '-- psql:<connection_name>'",
			vim.log.levels.ERROR
		)
		return
	end
	os.execute(string.format("echo > %s", output_file))

	local run_string = string.format('psql $(psqlcm show %s) -c "%s" &> %s', connection_name, sql_command, output_file)
	local job_id = vim.fn.jobstart(run_string, {
		on_exit = function(_, _, _)
			vim.notify("Query completed")
			vim.api.nvim_command("checktime")
		end,
	})
	vim.g["psql_job_id"] = job_id

	local bufs = vim.api.nvim_list_bufs()
	local foundoutput = false
	local buff_is_hidden = false
	for _, k in ipairs(bufs) do
		local buf_name = vim.api.nvim_buf_get_name(k)
		if string.find(buf_name, "psql.nvim.out$") ~= nil then
			buff_is_hidden = vim.fn.getbufinfo(k)[1].hidden == 1
			foundoutput = true
			break
		end
	end
	if not foundoutput or buff_is_hidden then
		vim.api.nvim_command("new")
		vim.api.nvim_command(string.format("e %s", output_file))
	end
end

local function psql_get_tables()
	psql_run_ad_hoc("\\d+")
end

local function psql_get_databases()
	psql_run_ad_hoc("\\l+")
end

local function psql_get_functions()
	psql_run_ad_hoc("\\df+")
end

local function psql_run_file(sql_file)
	local output_file = "/tmp/psql.nvim.out"
	local firstline = table.concat(vim.api.nvim_buf_get_lines(0, 0, 1, false), "")
	local connection_name = get_connection_name(firstline)
	if connection_name == nil or connection_name == "" then
		vim.notify("Invalid psqlcm connection identifier. Should be '-- psql:<connection_name>'", vim.log.levels.ERROR)
		return
	end
	os.execute(string.format("echo > %s", output_file))
	vim.api.nvim_command("write")

	local run_string = string.format("psql $(psqlcm show %s) -f %s &> %s", connection_name, sql_file, output_file)
	local job_id = vim.fn.jobstart(run_string, {
		on_exit = function(_, _, _)
			vim.notify("Query completed")
			vim.api.nvim_command("checktime")
		end,
	})
	vim.g["psql_job_id"] = job_id

	local bufs = vim.api.nvim_list_bufs()
	local foundoutput = false
	local buff_is_hidden = false
	for _, k in ipairs(bufs) do
		local buf_name = vim.api.nvim_buf_get_name(k)
		if string.find(buf_name, "psql.nvim.out$") ~= nil then
			buff_is_hidden = vim.fn.getbufinfo(k)[1].hidden == 1
			foundoutput = true
			break
		end
	end
	if not foundoutput or buff_is_hidden then
		vim.api.nvim_command("new")
		vim.api.nvim_command(string.format("e %s", output_file))
	end
end

local function psql_cancel()
	local job_id = vim.g["psql_job_id"]
	if job_id ~= nil then
		vim.fn.jobstop(job_id)
		vim.notify("Query cancelled")
	end
end

local function psql_run_visual()
	local tmp_sql_file = "/tmp/psql.nvim.sql"
	local f = assert(io.open(tmp_sql_file, "w"))

	local startpos = vim.fn.getpos("'<")
	local endpos = vim.fn.getpos("'>")
	local lines = vim.api.nvim_buf_get_lines(0, startpos[2] - 1, endpos[2], false)
	lines[1] = string.sub(lines[1], startpos[3], -1)

	local line_count = math.abs(endpos[2] - startpos[2]) + 1
	if line_count == 1 then
		lines[line_count] = string.sub(lines[line_count], 1, endpos[3] - startpos[3] + 1)
	else
		lines[line_count] = string.sub(lines[line_count], 1, endpos[3])
	end

	local visual_text = table.concat(lines, "\n")

	f:write(visual_text)
	f:close()

	psql_run_file(tmp_sql_file)
end

local function psql_run_curr_buf()
	local current_buf_name = vim.api.nvim_buf_get_name(0)
	if not is_sql_file(current_buf_name) then
		vim.notify("Not a SQL file!", vim.log.levels.ERROR)
		return
	end
	psql_run_file(current_buf_name)
end

local function psql_format()
	local current_buf_name = vim.api.nvim_buf_get_name(0)
	if not is_sql_file(current_buf_name) then
		vim.notify("Not a SQL file!", vim.log.levels.ERROR)
		return
	end
	os.execute(string.format("pg_format -i %s", current_buf_name))
	vim.api.nvim_command("edit")
end

local function psql_temp()
	local tmp_sql_file = "/tmp/psql.tmp.sql"
	os.execute(string.format("echo '-- psql:current' > %s", tmp_sql_file))
	vim.api.nvim_command("new")
	vim.api.nvim_command(string.format("e %s", tmp_sql_file))
end

return {
	psql_run_curr_buf = psql_run_curr_buf,
	psql_run_visual = psql_run_visual,
	psql_cancel = psql_cancel,
	psql_run_file = psql_run_file,
	psql_temp = psql_temp,
	psql_get_tables = psql_get_tables,
	psql_get_databases = psql_get_databases,
	psql_get_functions = psql_get_functions,
	psql_format = psql_format,
}
