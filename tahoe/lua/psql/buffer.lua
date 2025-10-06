local M = {}

local config = require("psql.config")

-- Buffer cache
local buffers = {}

-- Create a new buffer for query results
function M.create_results_buffer(query, results)
	local buf = vim.api.nvim_create_buf(false, true)

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "psql_results")

	-- Add buffer name
	local truncated_query = string.sub(query, 1, 30)
	if #query > 30 then
		truncated_query = truncated_query .. "..."
	end
	vim.api.nvim_buf_set_name(buf, "PSQL: " .. truncated_query)

	-- Format and add content
	local content = M.format_results(results)
	vim.api.nvim_buf_set_lines(buf, 0, -1, true, content)

	-- Add buffer to cache
	table.insert(buffers, buf)

	return buf
end

-- Format query results as a table
function M.format_results(results)
	if not results or #results == 0 then
		return { "No results" }
	end

	local lines = {}
	local headers = {}
	local col_widths = {}

	-- Get all column names and initialize widths
	for col, _ in pairs(results[1]) do
		table.insert(headers, col)
		col_widths[col] = #col
	end

	-- Sort headers for consistent output
	table.sort(headers)

	-- Calculate column widths
	for _, row in ipairs(results) do
		for _, col in ipairs(headers) do
			local value = row[col] or ""
			col_widths[col] = math.max(col_widths[col], #tostring(value))
		end
	end

	-- Add header row
	local header_line = "| "
	local separator = "+-"

	for _, col in ipairs(headers) do
		local width = col_widths[col]
		header_line = header_line .. string.format("%-" .. width .. "s | ", col)
		separator = separator .. string.rep("-", width) .. "-+-"
	end

	table.insert(lines, separator)
	table.insert(lines, header_line)
	table.insert(lines, separator)

	-- Add data rows
	for _, row in ipairs(results) do
		local line = "| "
		for _, col in ipairs(headers) do
			local width = col_widths[col]
			local value = row[col] or ""
			line = line .. string.format("%-" .. width .. "s | ", value)
		end
		table.insert(lines, line)
	end

	table.insert(lines, separator)
	table.insert(lines, string.format("%d rows", #results))

	return lines
end

-- Display buffer in appropriate window based on config
function M.display_buffer(buf)
	local display_mode = config.get("show_result_in")

	if display_mode == "split" then
		vim.cmd("split")
		vim.api.nvim_win_set_buf(0, buf)
	elseif display_mode == "vsplit" then
		vim.cmd("vsplit")
		vim.api.nvim_win_set_buf(0, buf)
	elseif display_mode == "tab" then
		vim.cmd("tabnew")
		vim.api.nvim_win_set_buf(0, buf)
	elseif display_mode == "float" then
		-- Create floating window
		local width = vim.api.nvim_get_option("columns")
		local height = vim.api.nvim_get_option("lines")

		local win_width = math.min(width - 10, 120)
		local win_height = math.min(height - 10, 30)

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
		-- Default to split
		vim.cmd("split")
		vim.api.nvim_win_set_buf(0, buf)
	end
end

-- Close all result buffers
function M.close_all_buffers()
	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
	end

	buffers = {}
end

return M
